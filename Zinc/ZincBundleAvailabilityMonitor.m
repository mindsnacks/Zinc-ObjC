//
//  ZincBundleCloneMonitor.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleAvailabilityMonitor.h"
#import "ZincRepo.h"
#import "ZincTask.h"
#import "ZincTaskDescriptor.h"
#import "ZincResource.h"
#import "ZincTaskActions.h"

@interface ZincBundleAvailabilityMonitor ()
@property (nonatomic, readwrite, retain) NSArray* bundleIDs;
@property (nonatomic, retain) NSMutableDictionary* myItems;
@property (nonatomic, readwrite, assign) float totalProgress;
@end

@interface ZincBundleAvailabilityMonitorItem ()
- (id) initWithMonitor:(ZincBundleAvailabilityMonitor*)monitor bundleID:(NSString*)bundleID;
@property (atomic, assign, readwrite) long long currentProgressValue;
@property (atomic, assign, readwrite) long long maxProgressValue;
@property (atomic, assign, readwrite) float progress;
@property (nonatomic, retain) ZincTask* task;
- (void) update;
@end

@implementation ZincBundleAvailabilityMonitor

@synthesize repo = _repo;
@synthesize bundleIDs = _bundleIDs;
@synthesize myItems = _myItems;

- (id)initWithRepo:(ZincRepo*)repo bundleIDs:(NSArray*)bundleIDs
{
    self = [super init];
    if (self) {
        _repo = [repo retain];
        _bundleIDs = [bundleIDs retain];
    }
    return self;
}

- (void)dealloc
{
    [_myItems release];
    [_repo release];
    [_bundleIDs release];
    [super dealloc];
}

- (NSArray*) items
{
    return [self.myItems allValues];
}

- (ZincBundleAvailabilityMonitorItem*) itemForBundleID:(NSString*)bundleID
{
    return [self.myItems objectForKey:bundleID];
}

- (void) update
{
    if (self.totalProgress == 1.0f) return;
    
    __block NSUInteger finishedCount = 0;
    
    [self.myItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        ZincBundleAvailabilityMonitorItem* item = obj;
        [item update];
        if (item.progress == 1.0f) {
            finishedCount++;
        }
    }];
    
    if (finishedCount == [self.myItems count]) {
        [self finish];
    } else {
        self.totalProgress = (float)finishedCount / [self.myItems count];
    }
}

- (void) finish
{
    self.totalProgress = 1.0f;
    if (self.completionBlock != nil) {
        self.completionBlock(nil); // TODO: add errors?
    }
    [self stopMonitoring];
}

- (void) monitoringDidStart
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskAdded:)
                                                 name:ZincRepoTaskAddedNotification
                                               object:self.repo];
    
    NSMutableDictionary* items = [NSMutableDictionary dictionaryWithCapacity:[self.bundleIDs count]];
    for (NSString* bundleID in self.bundleIDs) {
        ZincBundleAvailabilityMonitorItem* item = [[[ZincBundleAvailabilityMonitorItem alloc] initWithMonitor:self bundleID:bundleID] autorelease];
        [items setObject:item forKey:bundleID];
    }
    
    self.myItems = items;

    NSArray* existingTasks = [self.repo tasks];
    for (ZincTask* task in existingTasks) {
        [self associateTask:task];
    }
    
    [self update];
}

- (void) monitoringDidStop
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) associateTask:(ZincTask*)task
{
    if (![task.taskDescriptor.resource isZincBundleResource]) return;
    if (![task.taskDescriptor.action isEqualToString:ZincTaskActionUpdate]) return;
    
    NSString* taskBundleID = [task.resource zincBundleId];
    
    if (![self.bundleIDs containsObject:taskBundleID]) return;
    if ([self.repo stateForBundleWithId:taskBundleID] == ZincBundleStateAvailable) return;
    
    ZincBundleAvailabilityMonitorItem* item = [self.myItems objectForKey:taskBundleID];
    item.task = task;
}

- (void) taskAdded:(NSNotification*)note
{
    ZincTask* task = [[note userInfo] objectForKey:ZincRepoTaskNotificationTaskKey];

    [self associateTask:task];
}

@end


@implementation ZincBundleAvailabilityMonitorItem

@synthesize bundleID = _bundleID;
@synthesize task = _task;

- (id) initWithMonitor:(ZincBundleAvailabilityMonitor*)monitor bundleID:(NSString*)bundleID
{
    self = [super init];
    if (self) {
        _monitor = monitor;
        _bundleID = [bundleID retain];
    }
    return self;
}

- (void)dealloc
{
    [_bundleID release];
    [_task release];
    [super dealloc];
}

- (void)update
{
    if (self.progress == 1.0f) return;
    
    BOOL progressValuesChanged = NO;
    
    if ([self.monitor.repo stateForBundleWithId:self.bundleID] == ZincBundleStateAvailable
        || [self.task isFinished]) {
        
        progressValuesChanged = YES;
        self.currentProgressValue = self.maxProgressValue;
        self.progress = 1.0f;
        
    } else if (self.task != nil) {
        
        long long taskCurrentProgressValue = [self.task currentProgressValue];
        long long taskMaxProgressValue = [self.task maxProgressValue];
        
        if (self.currentProgressValue != taskCurrentProgressValue) {
            self.currentProgressValue = taskCurrentProgressValue;
            progressValuesChanged = YES;
        }
        
        if (self.maxProgressValue != taskMaxProgressValue) {
            self.maxProgressValue = taskMaxProgressValue;
            progressValuesChanged = YES;
        }
        
        if (progressValuesChanged) {
            self.progress = ZincProgressCalculate(self);
        }
    }
    
    if (progressValuesChanged && self.monitor.progressBlock != nil) {
        //NSLog(@"%lld %lld %f", self.currentProgressValue, self.maxProgressValue, self.progress);
        self.monitor.progressBlock(self, self.currentProgressValue, self.maxProgressValue, self.progress);
    }
}

@end