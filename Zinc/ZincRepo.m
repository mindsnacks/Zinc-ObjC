//
//  ZCBundleManager.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincRepoIndex.h"
#import "ZincBundle.h"
#import "ZincBundle+Private.h"
#import "ZincManifest.h"
#import "ZincSource.h"
#import "ZincCatalog.h"
#import "ZincEvent.h"
#import "ZincEvent+Private.h"
#import "ZincResource.h"
#import "ZincTask+Private.h"
#import "ZincTaskDescriptor.h"
#import "ZincBundleRemoteCloneTask.h"
#import "ZincBundleDeleteTask.h"
#import "ZincSourceUpdateTask.h"
#import "ZincCatalogUpdateTask.h"
#import "ZincObjectDownloadTask.h"
#import "ZincGarbageCollectTask.h"
#import "ZincCleanLegacySymlinksTask.h"
#import "ZincCompleteInitializationTask.h"
#import "ZincRepoIndexUpdateTask.h"
#import "ZincArchiveExtractOperation.h"
#import "ZincOperationQueueGroup.h"
#import "ZincUtils.h"
#import "NSFileManager+Zinc.h"
#import "NSData+Zinc.h"
#import "ZincJSONSerialization.h"
#import "ZincHTTPRequestOperation.h"
#import "ZincSerialQueueProxy.h"
#import "ZincErrors.h"
#import "ZincTrackingInfo.h"
#import "ZincTaskRef.h"
#import "ZincBundleTrackingRequest.h"
#import "ZincDownloadPolicy.h"
#import "ZincKSReachability.h"
#import "NSError+Zinc.h"
#import "ZincTaskActions.h"
#import "ZincExternalBundleInfo.h"

#define CATALOGS_DIR @"catalogs"
#define MANIFESTS_DIR @"manifests"
#define FILES_DIR @"objects"
#define BUNDLES_DIR @"bundles"
#define DOWNLOADS_DIR @"zinc/downloads"
#define REPO_INDEX_FILE @"repo.json"

NSString* const ZincRepoBundleStatusChangeNotification = @"ZincRepoBundleStatusChangeNotification";
NSString* const ZincRepoBundleWillDeleteNotification = @"ZincRepoBundleWillDeleteNotification";
NSString* const ZincRepoBundleDidBeginTrackingNotification = @"ZincRepoBundleDidBeginTrackingNotification";
NSString* const ZincRepoBundleWillStopTrackingNotification = @"ZincRepoBundleWillStopTrackingNotification";

NSString* const ZincRepoBundleChangeNotificationBundleIdKey = @"bundleId";
NSString* const ZincRepoBundleChangeNotifiationStatusKey = @"status";

NSString* const ZincRepoTaskAddedNotification = @"ZincRepoTaskAddedNotification";
NSString* const ZincRepoTaskFinishedNotification = @"ZincRepoTaskFinishedNotification";

NSString* const ZincRepoTaskNotificationTaskKey = @"task";


static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";

NSString* const ZincBundleStateName[] = {
    @"None",
    @"Cloning",
    @"Available",
    @"Deleting",
};

ZincBundleState ZincBundleStateFromName(NSString* name)
{
    if ([name isEqualToString:ZincBundleStateName[ZincBundleStateNone]]) {
        return ZincBundleStateNone;
    } else if ([name isEqualToString:ZincBundleStateName[ZincBundleStateAvailable]]) {
        return ZincBundleStateAvailable;
    } else if ([name isEqualToString:ZincBundleStateName[ZincBundleStateCloning]]) {
        return ZincBundleStateCloning;
    } else if ([name isEqualToString:ZincBundleStateName[ZincBundleStateDeleting]]) {
        return ZincBundleStateDeleting;
    }
    
    NSCAssert(NO, @"unknown bundle state name: %@", name);
    return -1;
}


@interface ZincRepo ()

@property (nonatomic, retain) NSURL* url;

// runtime state
@property (nonatomic, retain) NSMutableDictionary* sourcesByCatalog;
@property (nonatomic, retain) NSOperationQueue* networkQueue;
@property (nonatomic, retain) ZincOperationQueueGroup* queueGroup;
@property (nonatomic, retain) NSTimer* refreshTimer;
@property (nonatomic, retain) NSMutableDictionary* loadedBundles;
@property (nonatomic, retain) NSCache* cache;
@property (nonatomic, retain) NSMutableArray* myTasks;
@property (nonatomic, retain) NSFileManager* fileManager;
@property (nonatomic, retain, readwrite) ZincDownloadPolicy* downloadPolicy;
@property (nonatomic, retain) ZincKSReachability* reachability;
@property (nonatomic, retain) NSMutableDictionary* localFilesBySHA;
@property (nonatomic, retain) NSOperationQueue* initializationQueue;
@property (nonatomic, retain) ZincCompleteInitializationTask* completeInitializationTask;
@property (nonatomic, assign, readwrite) BOOL isInitialized;

@property (nonatomic, readonly) ZincSerialQueueProxy* indexProxy;

- (void) restartRefreshTimer;
- (void) stopRefreshTimer;

- (BOOL) createDirectoriesIfNeeded:(NSError**)outError;
- (NSString*) catalogsPath;
- (NSString*) manifestsPath;
- (NSString*) filesPath;
- (NSString*) bundlesPath;
- (NSString*) downloadsPath;

- (ZincTask*) queueIndexSaveTask;
- (ZincTask*) queueGarbageCollectTask;
- (void) resumeBundleActions;

- (NSString*) cacheKeyForCatalogId:(NSString*)identifier;
- (NSString*) cacheKeyManifestWithBundleId:(NSString*)identifier version:(ZincVersion)version;
- (NSString*) cacheKeyForBundleId:(NSString*)identifier version:(ZincVersion)version;

- (void) registerSource:(NSURL*)source forCatalog:(ZincCatalog*)catalog;
- (NSArray*) sourcesForCatalogId:(NSString*)catalogId;

- (ZincCatalog*) catalogWithIdentifier:(NSString*)source error:(NSError**)outError;

- (void) checkForBundleDeletion;
- (void) deleteBundleWithId:(NSString*)bundleId version:(ZincVersion)version;

- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
- (ZincManifest*) manifestWithBundleId:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError;

@end


@implementation ZincRepo

@synthesize delegate = _delegate;
@synthesize index = _index;
@synthesize url = _url;
@synthesize networkQueue = _networkQueue;
@synthesize sourcesByCatalog = _sourcesByCatalog;
@synthesize fileManager = _fileManager;
@synthesize cache = _cache;
@synthesize autoRefreshInterval = _refreshInterval;
@synthesize refreshTimer = _refreshTimer;
@synthesize loadedBundles = _loadedBundles;
@synthesize myTasks = _myTasks;
@synthesize queueGroup = _queueGroup;
@synthesize executeTasksInBackgroundEnabled = _shouldExecuteTasksInBackground;

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL error:(NSError**)outError
{
    NSOperationQueue* operationQueue = [[[NSOperationQueue alloc] init] autorelease];
    [operationQueue setMaxConcurrentOperationCount:kZincRepoDefaultNetworkOperationCount];
    return [self repoWithURL:fileURL networkOperationQueue:operationQueue error:outError];
}

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue error:(NSError**)outError
{
    if ([[[fileURL path] lastPathComponent] isEqualToString:REPO_INDEX_FILE]) {
        fileURL = [NSURL fileURLWithPath:[[fileURL path] stringByDeletingLastPathComponent]];
    }
    
    ZincKSReachability* reachability = [ZincKSReachability reachabilityToLocalNetwork];
    
    ZincRepo* repo = [[[ZincRepo alloc] initWithURL:fileURL networkOperationQueue:networkQueue reachability:reachability] autorelease];
    if (![repo createDirectoriesIfNeeded:outError]) {
        return nil;
    }
    
    NSString* indexPath = [[fileURL path] stringByAppendingPathComponent:REPO_INDEX_FILE];
    if ([repo.fileManager fileExistsAtPath:indexPath]) {
        
        NSData* jsonData = [[[NSData alloc] initWithContentsOfFile:indexPath options:0 error:outError] autorelease];
        if (jsonData == nil) {
            return nil;
        }
         
        NSDictionary* jsonDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:outError];
        if (jsonDict == nil) {
            return nil;
        }
        
        ZincRepoIndex* index = [ZincRepoIndex repoIndexFromDictionary:jsonDict error:outError];
        if (index == nil) {
            return nil;
        }
        repo.index = index;
    }
    
    [repo.queueGroup setSuspended:YES];
    
    if (![repo queueInitializationTasks]) {
        repo.isInitialized = YES;
    }

    [repo queueGarbageCollectTask];

    return repo;
}

+ (BOOL) repoExistsAtURL:(NSURL*)fileURL
{
    NSString* path = [fileURL path];
    if (![[path lastPathComponent] isEqualToString:REPO_INDEX_FILE]) {
        path = [path stringByAppendingPathComponent:REPO_INDEX_FILE];
    }
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}


- (id) initWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue reachability:(ZincKSReachability*)reachability
{
    self = [super init];
    if (self) {
        self.url = fileURL;
        self.index = [[[ZincRepoIndex alloc] init] autorelease];
        self.networkQueue = networkQueue;
        self.queueGroup = [[[ZincOperationQueueGroup alloc] init] autorelease];
        [self.queueGroup setIsBarrierOperationForClass:[ZincGarbageCollectTask class]];
        [self.queueGroup setIsBarrierOperationForClass:[ZincBundleDeleteTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:2 forClass:[ZincBundleRemoteCloneTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincCatalogUpdateTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:kZincRepoDefaultObjectDownloadCount forClass:[ZincObjectDownloadTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincSourceUpdateTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincArchiveExtractOperation class]];
        self.fileManager = [[[NSFileManager alloc] init] autorelease];
        self.cache = [[[NSCache alloc] init] autorelease];
        self.cache.countLimit = kZincRepoDefaultCacheCount;
        _refreshInterval = kZincRepoDefaultAutoRefreshInterval;
        self.sourcesByCatalog = [NSMutableDictionary dictionary];
        self.loadedBundles = [[[NSMutableDictionary alloc] init] autorelease];
        self.myTasks = [NSMutableArray array];
        self.executeTasksInBackgroundEnabled = YES;
        self.downloadPolicy = [[[ZincDownloadPolicy alloc] init] autorelease];
        self.reachability = reachability;
        self.localFilesBySHA = [NSMutableDictionary dictionary];
        self.initializationQueue = [[[NSOperationQueue alloc] init] autorelease];
        [self.initializationQueue setMaxConcurrentOperationCount:1];
    }
    return self;
}

/**
 @discussion Returns YES if initialization tasks are queued, NO otherwise
 */
- (BOOL) queueInitializationTasks
{
    NSAssert(!self.isInitialized, @"should not already be initialized");
    
    NSMutableArray* initOps = [NSMutableArray arrayWithCapacity:1];
    
    // Check for v1 -> v2 migration
    if (self.index.format == 1) {
        ZincCleanLegacySymlinksTask* cleanSymlinksTask = [[[ZincCleanLegacySymlinksTask alloc] initWithRepo:self resourceDescriptor:[self url]] autorelease];
        cleanSymlinksTask.completionBlock = ^{
            self.index.format = 2;
            [self queueIndexSaveTask];
        };
        [initOps addObject:cleanSymlinksTask];
        [self addOperation:cleanSymlinksTask];
    }
    
    if ([initOps count] > 0) {
        self.completeInitializationTask = [[[ZincCompleteInitializationTask alloc] initWithRepo:self resourceDescriptor:self.url] autorelease];
        
        for (NSOperation* initOp in initOps) {
            [self.completeInitializationTask addDependency:initOp];
        }
        [self addOperation:self.completeInitializationTask];
    }
    
    return self.completeInitializationTask != nil;
}

- (ZincTaskRef*) taskRefForInitialization
{
    @synchronized(self) {
        if (self.isInitialized || self.completeInitializationTask == nil) return nil;
        ZincTaskRef* taskRef = [ZincTaskRef taskRefForTask:self.completeInitializationTask];
        [self.initializationQueue addOperation:taskRef];
        return taskRef;
    }
}

- (void) waitForInitialization
{
    [[self taskRefForInitialization] waitUntilFinished];
}

- (void) setIsInitialized:(BOOL)isInitialized
{
    @synchronized(self) {
        if (isInitialized) {
            // no longer need to hold onto the initialization queue or task
            __block typeof(self) blockself = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                blockself.initializationQueue = nil;
                blockself.completeInitializationTask = nil;
            });
        }
        
        _isInitialized = isInitialized;
    }
}

- (void) completeInitialization
{
    self.isInitialized = YES;
}

- (void) setIndex:(ZincRepoIndex *)index
{
    [_index autorelease];
    
    if (index != nil) {
        ZincSerialQueueProxy* proxy = [[ZincSerialQueueProxy alloc] initWithTarget:index];
        _index = (ZincRepoIndex*)proxy;
    } else {
        _index = nil;
    }
}

- (void) setAutoRefreshInterval:(NSTimeInterval)refreshInterval
{
    _refreshInterval = refreshInterval;
    [self restartRefreshTimer];
}

- (void) setDownloadPolicy:(ZincDownloadPolicy *)downloadPolicy
{
    if (_downloadPolicy == downloadPolicy) return;
    
    if (_downloadPolicy != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:ZincDownloadPolicyPriorityChangeNotification
                                                      object:_downloadPolicy];
    }
    
    [_downloadPolicy release];
    _downloadPolicy = [downloadPolicy retain];
    
    if (_downloadPolicy != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downloadPolicyPriorityChangeNotification:)
                                                     name:ZincDownloadPolicyPriorityChangeNotification
                                                   object:_downloadPolicy];
    }
}

- (void) downloadPolicyPriorityChangeNotification:(NSNotification*)note
{
    NSString* bundleID = [[note userInfo] objectForKey:ZincDownloadPolicyPriorityChangeBundleIDKey];
    NSOperationQueuePriority priority = [[[note userInfo] objectForKey:ZincDownloadPolicyPriorityChangePriorityKey] integerValue];
    
    @synchronized(self.myTasks) {
        NSArray* tasks = [self tasksForBundleId:bundleID];
        for (ZincTask* task in tasks) {
            [task setQueuePriority:priority];
        }
    }
}

- (void) setReachability:(ZincKSReachability*)reachability
{
    if (_reachability == reachability) return;
    
    if (_reachability != nil) {
        _reachability.onReachabilityChanged = nil;
    }
    
    [_reachability release];
    _reachability = [reachability retain];
    
    if (_reachability != nil) {
        __block typeof(self) blockself = self;
        _reachability.onReachabilityChanged = ^(ZincKSReachability *reachability) {
            @synchronized(self.myTasks) {
                NSArray* remoteBundleUpdateTasks = [self.myTasks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                    return [evaluatedObject isKindOfClass:[ZincBundleRemoteCloneTask class]];
                }]];
                
                [remoteBundleUpdateTasks makeObjectsPerformSelector:@selector(updateReadiness)];
            }
            [blockself refreshSourcesWithCompletion:^{
                [blockself refreshBundlesWithCompletion:nil];
            }];
        };
    }
}

- (ZincSerialQueueProxy*) indexProxy
{
    return (ZincSerialQueueProxy*)self.index;
}

- (void) restartRefreshTimer
{
    [self stopRefreshTimer];
    
    if (self.autoRefreshInterval > 0) {
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.autoRefreshInterval
                                                             target:self
                                                           selector:@selector(refreshTimerFired:)
                                                           userInfo:nil
                                                            repeats:YES];
        [self.refreshTimer fire];
    }
}

- (void) stopRefreshTimer
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void) checkForBundleDeletion
{
    __block typeof(self) blockself = self;
    [self.indexProxy withTarget:^{
        
        NSSet* cloningBundles = [blockself.index cloningBundles];
        if ([cloningBundles count] > 1) {
            // don't delete while any clones are in progress
            return;
        }
        
        NSSet* available = [blockself.index availableBundles];
        NSSet* active = [blockself activeBundles];
        
        for (NSURL* bundleRes in available) {
            if (![active containsObject:bundleRes]) {
                //ZINC_DEBUG_LOG(@"deleting: %@", bundleRes);
                [blockself deleteBundleWithId:[bundleRes zincBundleId] version:[bundleRes zincBundleVersion]];
            }
        }
    }];
}

- (void) refreshWithCompletion:(dispatch_block_t)completion
{
    __block typeof(self) blockself = self;
    [blockself refreshSourcesWithCompletion:^{
        [blockself resumeBundleActions];
        [blockself refreshBundlesWithCompletion:^{
            [blockself checkForBundleDeletion];
            if (completion != nil) completion();
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

- (void)dealloc
{
    // set to nil to unsubscribe from notitifcations
    self.reachability = nil;
    self.downloadPolicy = nil;
    
    [_url release];
    [_index release];
    // TODO: stop operations?
    [_networkQueue release];
    [_queueGroup release];
    [_sourcesByCatalog release];
    [_cache release];
    [_loadedBundles release];
    [_myTasks release];
    [_initializationQueue release];
    [_completeInitializationTask release];
    [super dealloc];
}

#pragma mark Notifications

- (void) postNotification:(NSString*)notificationName userInfo:(NSDictionary*)userInfo
{
    __block typeof(self) blockself = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                            object:blockself
                                                          userInfo:userInfo];
    }];
}

- (void) postNotification:(NSString*)notificationName bundleId:(NSString*)bundleId state:(ZincBundleState)state
{
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              bundleId, ZincRepoBundleChangeNotificationBundleIdKey,
                              [NSNumber numberWithInteger:state], ZincRepoBundleChangeNotifiationStatusKey,
                              nil];
    [self postNotification:notificationName userInfo:userInfo];
}

- (void) postNotification:(NSString*)notificationName bundleId:(NSString*)bundleId
{
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              bundleId, ZincRepoBundleChangeNotificationBundleIdKey,
                              nil];
    [self postNotification:notificationName userInfo:userInfo];
}


#pragma mark Filesystem Utilities

- (BOOL) createDirectoriesIfNeeded:(NSError**)outError
{
    if (![self.fileManager zinc_createDirectoryIfNeededAtPath:[self catalogsPath] error:outError]) {
        return NO;
    }
    if (![self.fileManager zinc_createDirectoryIfNeededAtPath:[self manifestsPath] error:outError]) {
        return NO;
    }
    if (![self.fileManager zinc_createDirectoryIfNeededAtPath:[self filesPath] error:outError]) {
        return NO;
    }
    if (![self.fileManager zinc_createDirectoryIfNeededAtPath:[self bundlesPath] error:outError]) {
        return NO;
    }
    if (![self.fileManager zinc_createDirectoryIfNeededAtPath:[self downloadsPath] error:outError]) {
        return NO;
    }
    return YES;
}

#pragma mark Path Helpers

- (NSURL*) indexURL
{
    return [NSURL fileURLWithPath:[[self.url path] stringByAppendingPathComponent:REPO_INDEX_FILE]];
}

- (NSString*) catalogsPath
{
    return [[self.url path] stringByAppendingPathComponent:CATALOGS_DIR];
}

- (NSString*) manifestsPath
{
    return [[self.url path] stringByAppendingPathComponent:MANIFESTS_DIR];
}

- (NSString*) filesPath
{
    return [[self.url path] stringByAppendingPathComponent:FILES_DIR];
}

- (NSString*) bundlesPath
{
    return [[self.url path] stringByAppendingPathComponent:BUNDLES_DIR];
}

- (NSString*) downloadsPath
{
    return [ZincGetApplicationCacheDirectory() stringByAppendingPathComponent:DOWNLOADS_DIR];
}

- (NSString*) pathForCatalogIndexWithIdentifier:(NSString*)identifier
{
    NSString* catalogFilename =  [identifier stringByAppendingPathExtension:@"json"];
    NSString* catalogPath = [[self catalogsPath] stringByAppendingPathComponent:catalogFilename];
    return catalogPath;
}

- (NSString*) pathForCatalogIndex:(ZincCatalog*)catalog
{
    return [self pathForCatalogIndexWithIdentifier:catalog.identifier];
}

- (NSString*) pathForManifestWithBundleId:(NSString*)identifier version:(ZincVersion)version
{
    NSURL* bundleRes = [NSURL zincResourceForBundleWithId:identifier version:version];
    ZincExternalBundleInfo* extInfo = [self.index infoForExternalBundle:bundleRes];
    if (extInfo != nil) {
        return extInfo.manifestPath;
    }
    
    NSString* manifestFilename = [NSString stringWithFormat:@"%@-%d.json", identifier, version];
    NSString* manifestPath = [[self manifestsPath] stringByAppendingPathComponent:manifestFilename];
    return manifestPath;
}

- (NSString*) pathForFileWithSHA:(NSString*)sha
{
    return [[self filesPath] stringByAppendingPathComponent:sha];
}

- (BOOL) hasFileWithSHA:(NSString*)sha
{
    return [self.fileManager fileExistsAtPath:[self pathForFileWithSHA:sha]];
}

- (NSString*) externalPathForFileWithSHA:(NSString*)sha
{
    NSString* path = nil;
    @synchronized(self.localFilesBySHA) {
        path = self.localFilesBySHA[sha];
    }
    return path;
}

#pragma mark Internal Operations

- (void) addOperation:(NSOperation*)operation
{
    if ([operation isKindOfClass:[ZincURLConnectionOperation class]]) {
        [self.networkQueue addOperation:operation];
    } else if ([operation isKindOfClass:[ZincInitializationTask class]]) {
        [self.initializationQueue addOperation:operation];
    } else {
        [self.queueGroup addOperation:operation];
    }
}

#pragma mark Sources

- (void) addSourceURL:(NSURL*)source
{
    [self.index addSourceURL:source];
    [self queueIndexSaveTask];
    
    ZincTaskDescriptor* taskDesc = [ZincSourceUpdateTask taskDescriptorForResource:source];
    [self queueTaskForDescriptor:taskDesc];
}

- (void) removeSourceURL:(NSURL*)source
{
    @synchronized(self.sourcesByCatalog) {
        for (NSString* catalogId in [self.sourcesByCatalog allKeys]) {
            NSMutableArray* sources = [self.sourcesByCatalog objectForKey:catalogId];
            [sources removeObject:source];
        }
    }
    
    [self.index removeSourceURL:source];
    [self queueIndexSaveTask];
}

- (NSSet*) sourceURLs
{
    return [self.index sourceURLs];
}

- (void) registerSource:(NSURL*)source forCatalog:(ZincCatalog*)catalog
{
    @synchronized(self.sourcesByCatalog) {
        NSMutableArray* sources = [self.sourcesByCatalog objectForKey:catalog.identifier];
        if (sources == nil) {
            sources = [NSMutableArray array];
            [self.sourcesByCatalog setObject:sources forKey:catalog.identifier];
        }
        // TODO: cleaner duplicate check
        for (NSURL* existingSource in sources) {
            if ([existingSource isEqual:source]) {
                return;
            }
        }
        [sources addObject:source];
        [self.cache setObject:catalog forKey:[self cacheKeyForCatalogId:catalog.identifier]];
    }
}

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion
{
    NSSet* sourceURLs = [self.index sourceURLs];
    
    NSOperation* parentOp = nil;
    if (completion != nil) {
        parentOp = [[[NSOperation alloc] init] autorelease];
        parentOp.completionBlock = completion;
    }
    
    for (NSURL* source in sourceURLs) {
        ZincTaskDescriptor* taskDesc = [ZincSourceUpdateTask taskDescriptorForResource:source];
        ZincTask* task = (ZincSourceUpdateTask*)[self queueTaskForDescriptor:taskDesc];
        [parentOp addDependency:task];
    }
    
    if (completion != nil) {
        [self addOperation:parentOp];
    }
}

- (NSArray*) sourcesForCatalogId:(NSString*)catalogId
{
    return [self.sourcesByCatalog objectForKey:catalogId];
}

#pragma mark Caching

- (NSString*) cacheKeyForCatalogId:(NSString*)identifier
{
    return [@"Catalog:" stringByAppendingString:identifier];
}

- (NSString*) cacheKeyManifestWithBundleId:(NSString*)identifier version:(ZincVersion)version
{
    return [[@"Manifest:" stringByAppendingString:identifier] stringByAppendingFormat:@"-%d", version];
}

- (NSString*) cacheKeyForBundleId:(NSString*)identifier version:(ZincVersion)version
{
    return [[@"Bundle:" stringByAppendingString:identifier] stringByAppendingFormat:@"-%d", version];
}

#pragma mark Repo Index

- (ZincTask*) queueIndexSaveTask
{
    ZincTaskDescriptor* taskDesc = [ZincRepoIndexUpdateTask taskDescriptorForResource:[self indexURL]];
    return [self queueTaskForDescriptor:taskDesc];
}

#pragma mark Catalogs

- (void) registerCatalog:(ZincCatalog*)catalog
{
    NSString* key = [self cacheKeyForCatalogId:catalog.identifier];
    [self.cache setObject:catalog forKey:key];
}

- (ZincCatalog*) loadCatalogWithIdentifier:(NSString*)identifier error:(NSError**)outError
{
    NSString* catalogPath = [[[self catalogsPath] stringByAppendingPathComponent:identifier] stringByAppendingPathExtension:@"json"];
    NSData* jsonData = [NSData dataWithContentsOfFile:catalogPath options:0 error:outError];
    if (jsonData == nil) {
        return nil;
    }
    NSDictionary* jsonDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:outError];
    if (jsonDict == nil) {
        return nil;
    }
    ZincCatalog* catalog = [[[ZincCatalog alloc] initWithDictionary:jsonDict] autorelease];
    return catalog;
}

- (ZincCatalog*) catalogWithIdentifier:(NSString*)identifier error:(NSError**)outError
{
    NSString* key = [self cacheKeyForCatalogId:identifier];
    ZincCatalog* catalog = [self.cache objectForKey:key];
    if (catalog == nil) {
        catalog = [self loadCatalogWithIdentifier:identifier error:outError];
        if (catalog != nil) {
            [self.cache setObject:catalog forKey:key];
        }
    }
    return catalog;
}

#pragma mark Bundles

- (void) addManifest:(ZincManifest*)manifest forBundleId:(NSString*)bundleId
{
    NSString* cacheKey = [self cacheKeyManifestWithBundleId:bundleId version:manifest.version];
    [self.cache setObject:manifest forKey:cacheKey];
}

- (BOOL) removeManifestForBundleId:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError
{
    NSString* manifestPath = [self pathForManifestWithBundleId:bundleId version:version];
    if (![self.fileManager zinc_removeItemAtPath:manifestPath error:outError]) {
        return NO;
    }
    [self.cache removeObjectForKey:[self cacheKeyManifestWithBundleId:bundleId version:version]];
    return YES;
}

- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version
{
    NSString* path = [self pathForManifestWithBundleId:bundleId version:version];
    return [self.fileManager fileExistsAtPath:path];
}

- (ZincManifest*) importManifestWithPath:(NSString*)manifestPath error:(NSError**)outError
{
    // read manifest
    NSData* jsonData = [NSData dataWithContentsOfFile:manifestPath options:0 error:outError];
    if (jsonData == nil) {
        return nil;
    }
    
    // copy manifest to repo
    NSDictionary* manifestDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:outError];
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:manifestDict] autorelease];
    NSString* manifestRepoPath = [self pathForManifestWithBundleId:manifest.bundleId version:manifest.version];
    
    BOOL shouldCopy = NO;
    if (manifest.version == 0) {  // version 0 always needs to be re-written
        [self.fileManager removeItemAtPath:manifestRepoPath error:NULL];
        shouldCopy = YES;
    } else if (![self.fileManager fileExistsAtPath:manifestRepoPath]) {
        shouldCopy = YES;
    }
    
     if (shouldCopy) {
        if (![self.fileManager copyItemAtPath:manifestPath toPath:manifestRepoPath error:outError]) {
            return nil;
        }
    }
    
    return manifest;
}

- (ZincManifest*) loadManifestWithBundleId:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError
{
    NSString* manifestPath = [self pathForManifestWithBundleId:bundleId version:version];
    NSData* jsonData = [NSData dataWithContentsOfFile:manifestPath options:0 error:outError];
    if (jsonData == nil) {
        return nil;
    }
    NSDictionary* jsonDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:outError];
    if (jsonDict == nil) {
        return nil;
    }
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:jsonDict] autorelease];
    return manifest;
}

- (ZincManifest*) manifestWithBundleId:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError
{
    NSString* key = [self cacheKeyManifestWithBundleId:bundleId version:version];
    ZincManifest* manifest = [self.cache objectForKey:key];
    if (manifest == nil) {
        manifest = [self loadManifestWithBundleId:bundleId version:version error:outError];
        if (manifest != nil) {
            [self.cache setObject:manifest forKey:key];
        }
    }
    return [[manifest retain] autorelease];
}

- (NSSet*) activeBundles
{
    NSMutableSet* activeBundles = [NSMutableSet set];
    
    __block typeof(self) blockself = self;
    [self.indexProxy withTarget:^{
        NSSet* trackBundles = [blockself.index trackedBundleIds];
        for (NSString* bundleId in trackBundles) {
            NSString* dist = [blockself.index trackedDistributionForBundleId:bundleId];
            ZincVersion version = [blockself versionForBundleId:bundleId distribution:dist];
            [activeBundles addObject:[NSURL zincResourceForBundleWithId:bundleId version:version]];
        }
        
        [activeBundles addObjectsFromArray:[blockself.index registeredExternalBundles]];
    }];
    
    @synchronized(self.loadedBundles) {
        for (NSURL* bundleRes in [self.loadedBundles allKeys]) {
            // make sure to request the object, and check if the ref is now nil
            ZincBundle* bundle = [[self.loadedBundles objectForKey:bundleRes] pointerValue];
            if (bundle != nil) {
                [activeBundles addObject:bundleRes];
            }
        }
    }
    
    return activeBundles;
}

- (void) bundleWillDeallocate:(ZincBundle*)bundle
{
    @synchronized(self.loadedBundles) {
        [self.loadedBundles removeObjectForKey:[bundle resource]];
    }
}

- (ZincVersion) catalogVersionForBundleId:(NSString*)bundleId distribution:(NSString*)distro
{
    NSParameterAssert(bundleId);
    NSParameterAssert(distro);
    
    NSError* error = nil;
    
    NSString* catalogId = [ZincBundle catalogIdFromBundleId:bundleId];
    ZincCatalog* catalog = [self catalogWithIdentifier:catalogId error:&error];
    if (catalog != nil) {
        NSString* bundleName = [ZincBundle bundleNameFromBundleId:bundleId];
        ZincVersion catalogVersion = [catalog versionForBundleId:bundleName distribution:distro];
        
        if (catalogVersion == ZincVersionInvalid) {
            NSDictionary* info = @{@"bundleID" : bundleId, @"distro": distro};
            NSError* error = ZincErrorWithInfo(ZINC_ERR_DISTRO_NOT_FOUND_IN_CATALOG, info);
            [self logEvent:[ZincErrorEvent eventWithError:error source:self]];
        }
        
        return catalogVersion;
    }

    return ZincVersionInvalid;
}

- (ZincVersion) versionForBundleId:(NSString*)bundleId distribution:(NSString*)distro
{
    NSArray* availableVersions = [self.index availableVersionsForBundleId:bundleId];
    
    if ([availableVersions count] == 0) {
        return ZincVersionInvalid;
    }
    
    if (distro != nil) {
        ZincVersion catalogVersion = [self catalogVersionForBundleId:bundleId distribution:distro];
        if ([availableVersions containsObject:[NSNumber numberWithInteger:catalogVersion]]) {
            return catalogVersion;
        }
    }
    
    return [[availableVersions lastObject] integerValue];
}

- (BOOL) hasManifestForBundleId:(NSString *)bundleId distribution:(NSString*)distro
{
    NSString* catalogId = [ZincBundle catalogIdFromBundleId:bundleId];
    NSString* bundleName = [ZincBundle bundleNameFromBundleId:bundleId];
    ZincCatalog* catalog = [self catalogWithIdentifier:catalogId error:NULL];
    if (catalog == nil) {
        return NO;
    }
    ZincVersion version = [catalog versionForBundleId:bundleName distribution:distro];
    return [self hasManifestForBundleIdentifier:bundleId version:version];
}

- (NSOperationQueuePriority) initialPriorityForTask:(ZincTask*)task
{
    if ([task.resource isZincBundleResource]) {
        return [self.downloadPolicy priorityForBundleWithID:[task.resource zincBundleId]];
    }
    return NSOperationQueuePriorityNormal;
}

- (void) registerLocalFilesFromExternalManifest:(ZincManifest*)manifest bundleRootPath:(NSString*)bundleRoot
{
    @synchronized(self.localFilesBySHA) {
        NSArray* allFiles = [manifest allFiles];
        for (NSString* f in allFiles) {
            NSString* sha = [manifest shaForFile:f];
            self.localFilesBySHA[sha] = [bundleRoot stringByAppendingPathComponent:f];
        }
    }
}

- (BOOL) registerExternalBundleWithManifestPath:(NSString*)manifestPath bundleRootPath:(NSString*)rootPath error:(NSError**)outError
{
    ZincManifest* manifest = [ZincManifest manifestWithPath:manifestPath error:outError];
    if (manifestPath == nil) {
        return NO;
    }
    
    BOOL isDir;
    if (![self.fileManager fileExistsAtPath:rootPath isDirectory:&isDir] || !isDir) {
        if (outError != NULL) *outError = ZincError(ZINC_ERR_INVALID_DIRECTORY);
        return NO;
    }

    NSURL* bundleRes = [NSURL zincResourceForBundleWithId:manifest.bundleId version:manifest.version];
    [self.index registerExternalBundle:bundleRes manifestPath:manifestPath bundleRootPath:rootPath];
    
    [self registerLocalFilesFromExternalManifest:manifest bundleRootPath:rootPath];

    return YES;
}

- (void) beginTrackingBundleWithRequest:(ZincBundleTrackingRequest*)req
{
    NSParameterAssert(req);
    [self beginTrackingBundleWithId:req.bundleID distribution:req.distribution flavor:req.flavor automaticallyUpdate:req.updateAutomatically];
}

- (void) beginTrackingBundleWithId:(NSString*)bundleId distribution:(NSString*)distro automaticallyUpdate:(BOOL)autoUpdate
{
    NSParameterAssert(bundleId);
    NSParameterAssert(distro);
    [self beginTrackingBundleWithId:bundleId distribution:distro flavor:nil automaticallyUpdate:autoUpdate];
}

- (void) beginTrackingBundleWithId:(NSString*)bundleId distribution:(NSString*)distro flavor:(NSString*)flavor automaticallyUpdate:(BOOL)autoUpdate
{
    NSString* catalogId = ZincCatalogIdFromBundleId(bundleId);
    if (catalogId == nil) {
        [NSException raise:NSInvalidArgumentException
                    format:@"does not appear to be a valid bundle id"];
    }
    
    if (distro == nil) {
        [NSException raise:NSInvalidArgumentException
                    format:@"distro must not be nil"];
    }
    
    __block typeof(self) blockself = self;
    [self.indexProxy withTarget:^{
        ZincTrackingInfo* trackingInfo = [blockself.index trackingInfoForBundleId:bundleId];
        if (trackingInfo == nil) {
            trackingInfo = [[[ZincTrackingInfo alloc] init] autorelease];
        }

        if (trackingInfo.flavor != nil && ![trackingInfo.flavor isEqualToString:flavor]) {
            @throw [NSException
                    exceptionWithName:NSInternalInconsistencyException
                    reason:[NSString stringWithFormat:@"currently cannot re-track a different flavor"]
                    userInfo:nil];
        } else {
            trackingInfo.flavor = flavor;
        }

        trackingInfo.distribution = distro;
        trackingInfo.updateAutomatically = autoUpdate;
        
        if (autoUpdate) {
            trackingInfo.version = [blockself catalogVersionForBundleId:bundleId distribution:distro];
        }
        [blockself.index setTrackingInfo:trackingInfo forBundleId:bundleId];
        [blockself queueIndexSaveTask];
        
        [blockself postNotification:ZincRepoBundleDidBeginTrackingNotification bundleId:bundleId];
    }];
}

- (ZincTaskRef*) updateBundleWithID:(NSString*)bundleID
{
    ZincTaskRef* taskRef = [[[ZincTaskRef alloc] init] autorelease];
    [self updateBundleWithID:bundleID taskRef:taskRef];
    return taskRef;
}

- (void) updateBundleWithID:(NSString*)bundleID completionBlock:(ZincCompletionBlock)completion
{
    ZincTaskRef* taskRef = nil;
    if (completion != nil) {
        taskRef = [[[ZincTaskRef alloc] init] autorelease];
        __block typeof(taskRef) block_taskRef = taskRef;
        taskRef.completionBlock = ^{
            completion([block_taskRef allErrors]);
        };
    }
    [self updateBundleWithID:bundleID taskRef:taskRef];
}

- (void) updateBundleWithID:(NSString*)bundleID taskRef:(ZincTaskRef*)taskRef
{
    NSParameterAssert(bundleID);
    NSParameterAssert(taskRef);
    
    __block typeof(self) blockself = self;
    [blockself.indexProxy withTarget:^{
        
        ZincTrackingInfo* trackingInfo = [blockself.index trackingInfoForBundleId:bundleID];
        if (trackingInfo == nil) {
            NSDictionary* info = @{@"bundleID" : bundleID};
            [taskRef addError:ZincErrorWithInfo(ZINC_ERR_NO_TRACKING_DISTRO_FOR_BUNDLE, info)];
            return;
        }
        
        ZincVersion version = [blockself catalogVersionForBundleId:bundleID distribution:trackingInfo.distribution];
        if (version == ZincVersionInvalid) {
            [taskRef addError:ZincError(ZINC_ERR_BUNDLE_NOT_FOUND_IN_CATALOGS)];
            return;
        }
        
        trackingInfo.version = version;
        [blockself.index setTrackingInfo:trackingInfo forBundleId:bundleID];
        
        NSURL* bundleRes = [NSURL zincResourceForBundleWithId:bundleID version:version];
        
        ZincBundleState state = [blockself.index stateForBundle:bundleRes];
        if (state != ZincBundleStateAvailable) {
            [blockself.index setState:ZincBundleStateCloning forBundle:bundleRes];
            ZincTaskDescriptor* taskDesc = [ZincBundleRemoteCloneTask taskDescriptorForResource:bundleRes];
            ZincTask* task = [blockself queueTaskForDescriptor:taskDesc];
            [taskRef addDependency:task];
        }
    }];
    
    if (taskRef != nil) [blockself addOperation:taskRef];
    [blockself queueIndexSaveTask];
}

- (void) stopTrackingBundleWithId:(NSString*)bundleId
{
    [self postNotification:ZincRepoBundleWillStopTrackingNotification bundleId:bundleId];
    
    [self.index removeTrackedBundleId:bundleId];
    [self queueIndexSaveTask];  
}

- (NSSet*) trackedBundleIds
{
    return [self.index trackedBundleIds];
}

- (void) resumeBundleActions
{
    __block typeof(self) blockself = self;
    [blockself.indexProxy withTarget:^{
        for (NSURL* bundleRes in [blockself.index cloningBundles]) {
            if ([bundleRes zincBundleVersion] > 0) {
                [blockself queueTaskForDescriptor:[ZincBundleRemoteCloneTask taskDescriptorForResource:bundleRes]];
            }
        }
    }];
}

- (BOOL) doesPolicyAllowDownloadForBundleID:(NSString*)bundleID
{
    ZincConnectionType requiredConnectionType = [self.downloadPolicy requiredConnectionTypeForBundleID:bundleID];

    if (requiredConnectionType == ZincConnectionTypeWiFiOnly && [self.reachability WWANOnly]) {
        return NO;
    }
    return YES;
}

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion
{
    NSOperation* parentOp = nil;
    if (completion != nil) {
        parentOp = [[[NSOperation alloc] init] autorelease];
        parentOp.completionBlock = completion;
    }
    
    __block typeof(self) blockself = self;
    [self.indexProxy withTarget:^{
        
        NSSet* trackBundles = [blockself.index trackedBundleIds];
        
        for (NSString* bundleId in trackBundles) {
            
            ZincTrackingInfo* trackingInfo = [blockself.index trackingInfoForBundleId:bundleId];
            
            ZincVersion targetVersion = ZincVersionInvalid;
            
            /*
               - if auto updates are enabled, we always want to look in the catalog
               - if not, BUT the version is invalid, it means that we weren't able to clone any version yet
             */
            // TODO: this really needs to be testable
            if (trackingInfo.updateAutomatically || trackingInfo.version == ZincVersionInvalid) {
                targetVersion = [blockself catalogVersionForBundleId:bundleId distribution:trackingInfo.distribution];
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
            if (![blockself doesPolicyAllowDownloadForBundleID:bundleId]) {
                continue;
            }
            
            NSURL* bundleRes = [NSURL zincResourceForBundleWithId:bundleId version:targetVersion];
            ZincBundleState state = [blockself.index stateForBundle:bundleRes];
            
            if (state == ZincBundleStateCloning || state == ZincBundleStateAvailable) {
                // already downloading/downloaded
                continue;
            }

            [blockself.index setState:ZincBundleStateCloning forBundle:bundleRes];
            [blockself queueIndexSaveTask];
            
            ZincTaskDescriptor* taskDesc = [ZincBundleRemoteCloneTask taskDescriptorForResource:bundleRes];
            ZincTask* bundleTask = [blockself queueTaskForDescriptor:taskDesc];
            [parentOp addDependency:bundleTask];
        }
    }];
    
    if (completion != nil) {
        [self addOperation:parentOp];
    }
}

- (void) deleteBundleWithId:(NSString*)bundleId version:(ZincVersion)version
{
    NSURL* bundleRes = [NSURL zincResourceForBundleWithId:bundleId version:version];
    ZincTaskDescriptor* taskDesc = [ZincBundleDeleteTask taskDescriptorForResource:bundleRes];
    [self queueTaskForDescriptor:taskDesc];
}

#pragma mark Bundles

- (void) registerBundle:(NSURL*)bundleResource status:(ZincBundleState)status
{
    [self.index setState:status forBundle:bundleResource];
    [self postNotification:ZincRepoBundleStatusChangeNotification bundleId:[bundleResource zincBundleId] state:status];
    [self queueIndexSaveTask];
}

- (void) deregisterBundle:(NSURL*)bundleResource completion:(dispatch_block_t)completion
{
    [self postNotification:ZincRepoBundleWillDeleteNotification bundleId:[bundleResource zincBundleId]];
    [self.index removeBundle:bundleResource];
    ZincTask* saveTask = [self queueIndexSaveTask];
    if (completion != nil) {
        ZincTaskRef* taskRef = [[[ZincTaskRef alloc] init] autorelease];
        [taskRef addDependency:saveTask];
        taskRef.completionBlock = completion;
        [self addOperation:taskRef];
    }
}

- (void) deregisterBundle:(NSURL*)bundleResource
{
    [self deregisterBundle:bundleResource completion:nil];
}

- (NSString*) pathForBundleWithId:(NSString*)bundleId version:(ZincVersion)version
{
    NSURL* bundleRes = [NSURL zincResourceForBundleWithId:bundleId version:version];
    ZincExternalBundleInfo* extInfo = [self.index infoForExternalBundle:bundleRes];
    if (extInfo != nil) {
        return extInfo.bundleRootPath;
    }
    
    NSString* bundleDirName = [NSString stringWithFormat:@"%@-%d", bundleId, version];
    NSString* bundlePath = [[self bundlesPath] stringByAppendingPathComponent:bundleDirName];
    return bundlePath;
}

- (ZincBundle*) bundleWithId:(NSString*)bundleId version:(ZincVersion)version
{
    ZincBundle* bundle = nil;
    NSURL* res = [NSURL zincResourceForBundleWithId:bundleId version:version];
    NSString* path = [self pathForBundleWithId:bundleId version:version];
    
    // Special case to handle a missing bundle dir
    if (![self.fileManager fileExistsAtPath:path]) {
        
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_enter(group);
        [self deregisterBundle:res completion:^{
            dispatch_group_leave(group);
        }];
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        dispatch_release(group);
        
        return nil;
    }
    
    @synchronized(self.loadedBundles) {
        bundle = [[self.loadedBundles objectForKey:res] pointerValue];
        
        if (bundle == nil) {
            bundle = [[[ZincBundle alloc] initWithRepo:self bundleId:bundleId version:version bundleURL:[NSURL fileURLWithPath:path]] autorelease];
            if (bundle == nil) return nil;
            
            [self.loadedBundles setObject:[NSValue valueWithPointer:bundle] forKey:res];
        }
        [[bundle retain] autorelease];
    }
    return bundle;
}

- (ZincBundleState) stateForBundleWithId:(NSString*)bundleId 
{
    __block ZincBundleState state;
    __block typeof(self) blockself = self;
    [self.indexProxy withTarget:^{
        NSString* distro = [blockself.index trackedDistributionForBundleId:bundleId];
        ZincVersion version = [blockself versionForBundleId:bundleId distribution:distro];
        NSURL* bundleRes = [NSURL zincResourceForBundleWithId:bundleId version:version];
        state = [blockself.index stateForBundle:bundleRes];
    }];
    return state;
}

- (ZincBundle*) bundleWithId:(NSString*)bundleId
{
    if (!self.isInitialized) {
        @throw [NSException
                exceptionWithName:NSInternalInconsistencyException
                reason:[NSString stringWithFormat:@"repo not initialized"]
                userInfo:nil];
    }

    NSString* distro = [self.index trackedDistributionForBundleId:bundleId];
    ZincVersion version = [self versionForBundleId:bundleId distribution:distro];
    if (version == ZincVersionInvalid) {
        return nil;
    }
    
    return [self bundleWithId:bundleId version:version];
}

#pragma mark Tasks

- (NSArray*) tasks
{
    return [NSArray arrayWithArray:self.myTasks];
}

- (void) suspendAllTasks
{
    [self stopRefreshTimer];
    [self.queueGroup setSuspended:YES];
}

- (void) suspendAllTasksAndWaitExecutingTasksToComplete
{
    [self suspendAllTasks];
    [self.queueGroup suspendAndWaitForExecutingOperationsToComplete];
}

- (void) resumeAllTasks
{
    [self.queueGroup setSuspended:NO];
    [self restartRefreshTimer];
}

- (BOOL) isSuspended
{
    return self.refreshTimer == nil;
}

- (ZincTask*) taskForDescriptor:(ZincTaskDescriptor*)taskDescriptor
{
    @synchronized(self.myTasks) {
        for (ZincTask* task in self.myTasks) {
            if ([[task taskDescriptor] isEqual:taskDescriptor]) {
                return task;
            }
        }
    }
    return nil;
}

- (NSArray*) tasksForResource:(NSURL*)resource
{
    @synchronized(self.myTasks) {
        NSMutableArray* tasks = [NSMutableArray array];
        for (ZincTask* task in self.myTasks) {
            if ([task.resource isEqual:resource]) {
                [tasks addObject:task];
            }
        }
        return tasks;
    }
}

- (NSArray*) tasksWithMethod:(NSString*)method
{
    @synchronized(self.myTasks) {
        return [self.myTasks filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"method = %@", method]];
    }
}

- (NSArray*) tasksForBundleId:(NSString*)bundleId
{
    @synchronized(self.myTasks)
    {
        NSMutableArray* tasks = [NSMutableArray array];
        for (ZincTask* task in self.myTasks) {
            if ([task.resource isZincBundleResource]) {
                if ([[task.resource zincBundleId] isEqualToString:bundleId]) {
                    [tasks addObject:task];
                }
            }
        }
        return tasks;
    }
}

- (void) queueTask:(ZincTask*)task
{
    task.queuePriority = [self initialPriorityForTask:task];
    if (self.executeTasksInBackgroundEnabled) {
        [task setShouldExecuteAsBackgroundTask];
    }

    @synchronized(self.myTasks) {
        [self.myTasks addObject:task];
        [task addObserver:self forKeyPath:@"isFinished" options:0 context:&kvo_taskIsFinished];
        [self addOperation:task];
    }
    
    [self postNotification:ZincRepoTaskAddedNotification
                  userInfo:@{ ZincRepoTaskNotificationTaskKey : task }];

}

- (void)cleanWithCompletion:(dispatch_block_t)completion
{
    ZincTaskRef* taskRef = [[[ZincTaskRef alloc] init] autorelease];
    ZincTask* garbageTask = [self queueGarbageCollectTask];
    [taskRef addDependency:garbageTask];
    taskRef.completionBlock = completion;
    [self addOperation:taskRef];
}

- (ZincTask*) queueGarbageCollectTask
{
    ZincTaskDescriptor* taskDesc = [ZincGarbageCollectTask taskDescriptorForResource:self.url];
    return [self queueTaskForDescriptor:taskDesc];
}

- (ZincTask*) queueCleanSymlinksTask
{
    ZincTaskDescriptor* taskDesc = [ZincCleanLegacySymlinksTask taskDescriptorForResource:self.url];
    return [self queueTaskForDescriptor:taskDesc];
}

- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input dependencies:(NSArray*)dependencies
{
    __block ZincTask* task = nil;
    
    [self.indexProxy withTarget:^{ // use indexProxy for synchronization

        NSArray* tasksMatchingResource = [self tasksForResource:taskDescriptor.resource];

        // Check for exact match
        ZincTask* existingTask = [self taskForDescriptor:taskDescriptor];
        if (existingTask == nil) {
            // look for task that also matches the action
            for (ZincTask* potentialMatchingTask in tasksMatchingResource) {
                if ([[potentialMatchingTask taskDescriptor].action isEqual:taskDescriptor.action]) {
                    existingTask = potentialMatchingTask;
                }
            }
            
            // if no exact match found, add task and depends for all other resource-matching
            if (existingTask == nil) {
                task = [ZincTask taskWithDescriptor:taskDescriptor repo:self input:input];
                for (ZincTask* resourceTask in tasksMatchingResource) {
                    if (resourceTask != task) {
                        [task addDependency:resourceTask];
                    }
                }
            }
        }
        
        if (existingTask != nil) {
            task = existingTask;
        }
        
        NSAssert(task, @"task is nil");
        
        // add all explicit deps
        for (NSOperation* dep in dependencies) {
            [task addDependency:dep];
        }
        
        // finally queue task if it was not pre-existing
        if (existingTask == nil) {
            [self queueTask:task];
        }
    }];
    
    return task;
}

- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input
{
    return [self queueTaskForDescriptor:taskDescriptor input:input dependencies:nil];
}

- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor
{
    return [self queueTaskForDescriptor:taskDescriptor input:nil];
}

-  (void) removeTask:(ZincTask*)task
{
    ZincTask* foundTask = nil;
    @synchronized(self.myTasks) {
        ZincTask* foundTask = [self taskForDescriptor:[task taskDescriptor]];
        if (foundTask != nil) {
            [foundTask removeObserver:self forKeyPath:@"isFinished" context:&kvo_taskIsFinished];
            [self.myTasks removeObject:foundTask];
        }
    }
    
    if (foundTask != nil) {
        [self postNotification:ZincRepoTaskFinishedNotification
                      userInfo:@{ ZincRepoTaskNotificationTaskKey : foundTask }];
    }
}

- (void) logEvent:(ZincEvent*)event
{
    __block typeof(self) blockself = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([blockself.delegate respondsToSelector:@selector(zincRepo:didReceiveEvent:)])
            [blockself.delegate zincRepo:blockself didReceiveEvent:event];
        
        NSMutableDictionary* userInfo = [[event.attributes mutableCopy] autorelease];
        [[NSNotificationCenter defaultCenter] postNotificationName:[[event class] notificationName] object:self userInfo:userInfo];        
    }];
}

+ (void)setDefaultThreadPriority:(double)defaultThreadPriority
{
    [ZincOperation setDefaultThreadPriority:defaultThreadPriority];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kvo_taskIsFinished) {
        ZincTask* task = (ZincTask*)object;
        if (task.isFinished) {
            [self removeTask:task];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end



