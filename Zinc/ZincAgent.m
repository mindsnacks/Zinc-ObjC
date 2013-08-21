//
//  ZincRepoAgent.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/30/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincAgent+Private.h"

#import <KSReachability/KSReachability.h>

#import "ZincInternals.h"

#import "ZincRepo+Private.h"
#import "ZincDownloadPolicy+Private.h"
#import "ZincTask+Private.h"


@interface ZincAgent ()

@property (nonatomic, strong, readwrite) ZincRepo *repo;
@property (nonatomic, weak) NSTimer* refreshTimer;
@property (nonatomic, strong, readwrite) ZincDownloadPolicy* downloadPolicy;

@end

static NSMutableDictionary* _AgentsByURL;


@implementation ZincAgent

+ (void) initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _AgentsByURL = [[NSMutableDictionary alloc] initWithCapacity:2];
    });
}

+ (instancetype) agentForRepo:(ZincRepo*)repo
{
    ZincAgent* agent = nil;

    @synchronized(_AgentsByURL) {
        agent = [_AgentsByURL[repo.url] pointerValue];

        if (agent == nil) {
            KSReachability* reachability = [KSReachability reachabilityToLocalNetwork];
            agent = [[ZincAgent alloc] initWithRepo:repo reachability:reachability];
            _AgentsByURL[repo.url] = [NSValue valueWithPointer:(__bridge const void *)(agent)];
        }
    }

    return agent;
}

- (id)initWithRepo:(ZincRepo *)repo reachability:(KSReachability *)reachability
{
    self = [super init];
    if (self) {
        self.repo = repo;
        self.reachability = reachability;
        _autoRefreshInterval = kZincAgentDefaultAutoRefreshInterval;
        self.downloadPolicy = [[ZincDownloadPolicy alloc] init];
    }
    return self;
} 

- (void)dealloc
{
    // set to nil to unsubscribe from notitifcations
    self.reachability = nil;
    self.downloadPolicy = nil;

    @synchronized(_AgentsByURL) {
        [_AgentsByURL removeObjectForKey:self.repo.url];
    }
}

- (void) setReachability:(KSReachability*)reachability
{
    if (_reachability == reachability) return;

    if (_reachability != nil) {
        _reachability.onReachabilityChanged = nil;
    }

    _reachability = reachability;

    if (_reachability != nil) {

        __weak typeof(self) weakself = self;

        _reachability.onReachabilityChanged = ^(KSReachability *reachability) {

            __strong typeof(weakself) strongself = weakself;

            // TODO: move this inside task manager?
            @synchronized(strongself.repo.taskManager.tasks) {
                NSArray* remoteBundleUpdateTasks = [strongself.repo.tasks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                    return [evaluatedObject isKindOfClass:[ZincBundleRemoteCloneTask class]];
                }]];
                [remoteBundleUpdateTasks makeObjectsPerformSelector:@selector(updateReadiness)];
            }

            [strongself refreshWithCompletion:nil];
        };
    }
}

- (void) setDownloadPolicy:(ZincDownloadPolicy *)downloadPolicy
{
    if (_downloadPolicy == downloadPolicy) return;

    if (_downloadPolicy != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:ZincDownloadPolicyPriorityChangeNotification
                                                      object:_downloadPolicy];
    }

    _downloadPolicy = downloadPolicy;

    if (_downloadPolicy != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downloadPolicyPriorityChangeNotification:)
                                                     name:ZincDownloadPolicyPriorityChangeNotification
                                                   object:_downloadPolicy];
    }
}

- (void) downloadPolicyPriorityChangeNotification:(NSNotification*)note
{
    NSString* bundleID = [note userInfo][ZincDownloadPolicyPriorityChangeBundleIDKey];
    NSOperationQueuePriority priority = [[note userInfo][ZincDownloadPolicyPriorityChangePriorityKey] integerValue];

    @synchronized(self.repo.taskManager.tasks) {
        NSArray* tasks = [self.repo.taskManager tasksForBundleID:bundleID];
        for (ZincTask* task in tasks) {
            [task setQueuePriority:priority];
        }
    }
}

- (void) setAutoRefreshInterval:(NSTimeInterval)refreshInterval
{
    _autoRefreshInterval = refreshInterval;
    [self restartRefreshTimer];
}

- (void) restartRefreshTimer
{
    @synchronized(self)
    {
        [self stopRefreshTimer];

        if (self.autoRefreshInterval > 0) {
            self.refreshTimer = [NSTimer timerWithTimeInterval:self.autoRefreshInterval
                                                        target:self
                                                      selector:@selector(refreshTimerFired:)
                                                      userInfo:nil
                                                       repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:self.refreshTimer forMode:NSRunLoopCommonModes];
            [self.refreshTimer fire];
        }
    }
}

- (void) stopRefreshTimer
{
    @synchronized(self)
    {
        [self.refreshTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
        self.refreshTimer = nil;
    }
}

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion
{
    [self.repo refreshSourcesWithCompletion:completion];
}

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion
{
    NSOperation* parentOp = nil;
    if (completion != nil) {
        parentOp = [[NSOperation alloc] init];
        parentOp.completionBlock = completion;
    }

    NSMutableArray *bundlesToUpdate = [NSMutableArray array];

    @synchronized(self.repo.index) {

        NSSet* trackBundles = [self.repo.index trackedBundleIDs];

        for (NSString* bundleID in trackBundles) {

            ZincTrackingInfo* trackingInfo = [self.repo.index trackingInfoForBundleID:bundleID];
            ZincVersion targetVersion = ZincVersionInvalid;

            // TODO: this really needs to be testable
            if (trackingInfo.version == ZincVersionInvalid) {
                targetVersion = [self.repo catalogVersionForBundleID:bundleID distribution:trackingInfo.distribution];
            } else {
                targetVersion = trackingInfo.version;
            }

            if (targetVersion == ZincVersionInvalid) {
                continue;
            }

            /*
             small optimization to prevent tasks tasks aren't allowed by policy to be enqueued
             task will still respect isReady as well
             */
            if (![self doesPolicyAllowDownloadForBundleID:bundleID]) {
                continue;
            }

            NSURL* bundleRes = [NSURL zincResourceForBundleWithID:bundleID version:targetVersion];
            ZincBundleState state = [self.repo.index stateForBundle:bundleRes];

            if (state == ZincBundleStateCloning || state == ZincBundleStateAvailable) {
                // already downloading/downloaded
                continue;
            }

            [bundlesToUpdate addObject:bundleRes];
        }
    }

    // the following should not be done within an @synchronized block because it obtains other locks

    for (NSURL* bundleRes in bundlesToUpdate) {
        NSOperationQueuePriority priority = [self.downloadPolicy priorityForBundleWithID:[bundleRes zincBundleID]];
        [self.repo queueBundleCloneTaskForBundle:bundleRes priority:priority];
    }

    [self.repo.taskManager queueIndexSaveTask];

    if (completion != nil) {
        [self.repo.taskManager addOperation:parentOp];
    }
}

- (void) refreshWithCompletion:(dispatch_block_t)completion
{
    __weak typeof(self) weakself = self;

    [self refreshSourcesWithCompletion:^{

        __strong typeof(weakself) strongself = weakself;

        [strongself resumeBundleActions];

        __weak typeof(strongself) weakself2 = strongself;

        [strongself refreshBundlesWithCompletion:^{

            __strong typeof(weakself2) strongself2 = weakself2;

            [strongself2.repo cleanWithCompletion:^{

                if (completion != nil) completion();

            }];
        }];
    }];
}

- (void) refresh
{
    [self refreshWithCompletion:nil];
}

- (void) refreshTimerFired:(NSTimer*)timer
{
    [self refresh];
}

- (void) resumeBundleActions
{
    NSSet* cloningBundles = [self.repo.index cloningBundles];
    for (NSURL* bundleRes in cloningBundles) {
        if ([bundleRes zincBundleVersion] > 0) {
            [self.repo.taskManager queueTaskForDescriptor:[ZincBundleRemoteCloneTask taskDescriptorForResource:bundleRes]];
        }
    }
}

- (BOOL) doesPolicyAllowDownloadForBundleID:(NSString*)bundleID
{
    // TODO: this logic makes more sense in the ZincDownloadPolicy object, but
    // I also hestitate to add reachability support to it directly.

    ZincConnectionType requiredConnectionType = [self.downloadPolicy requiredConnectionTypeForBundleID:bundleID];

    if (requiredConnectionType == ZincConnectionTypeWiFiOnly && [self.reachability WWANOnly]) {
        return NO;
    }

    return [self.downloadPolicy doRulesAllowBundleID:bundleID];
}

@end
