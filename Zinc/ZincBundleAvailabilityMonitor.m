//
//  ZincBundleCloneMonitor.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleAvailabilityMonitor.h"

#import "ZincInternals.h"
#import "ZincActivityMonitor+Private.h"
#import "ZincRepo.h"
#import "ZincTaskActions.h"


@interface ZincBundleAvailabilityMonitor ()
@property (nonatomic, readwrite, copy) NSArray* bundleIDs;
@property (nonatomic, strong) NSMutableDictionary* myItems;
@property (nonatomic, readwrite, assign) float totalProgress;
@end


@interface ZincBundleAvailabilityMonitorItem ()
- (id) initWithMonitor:(ZincBundleAvailabilityMonitor*)monitor bundleID:(NSString*)bundleID;
@end


@implementation ZincBundleAvailabilityMonitor

- (id)initWithRepo:(ZincRepo*)repo bundleIDs:(NSArray*)bundleIDs
{
    self = [super init];
    if (self) {
        _repo = repo;
        self.bundleIDs = bundleIDs;
    }
    return self;
}

- (NSArray*) items
{
    return [self.myItems allValues];
}

- (ZincBundleAvailabilityMonitorItem*) itemForBundleID:(NSString*)bundleID
{
    return (self.myItems)[bundleID];
}

- (void) update
{
    if ([self isFinished]) return;
    
    [[self items] makeObjectsPerformSelector:@selector(update)];
    
    NSArray* finishedItems = [[self items] filteredArrayUsingPredicate:
                              [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isFinished];
    }]];
       
    if ([finishedItems count] == [self.myItems count]) {
        [self finish];
    } else {
        self.totalProgress = [[[self.myItems allValues]  valueForKeyPath:@"@avg.progress"] floatValue];
        
        ZINC_DEBUG_LOG(@"total %f", self.totalProgress);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ZincActivityMonitorRefreshedNotification object:self];
}

- (void) finish
{
    self.totalProgress = 1.0f;
    if (self.completionBlock != nil) {
        self.completionBlock(nil); // TODO: add errors?
    }
    [self stopMonitoring];
}

- (BOOL) isFinished
{
    return self.totalProgress == 1.0f;
}

- (void) monitoringDidStart
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskAdded:)
                                                 name:ZincRepoTaskAddedNotification
                                               object:self.repo];
    
    NSMutableDictionary* items = [NSMutableDictionary dictionaryWithCapacity:[self.bundleIDs count]];
    for (NSString* bundleID in self.bundleIDs) {
        ZincBundleAvailabilityMonitorItem* item = [[ZincBundleAvailabilityMonitorItem alloc] initWithMonitor:self bundleID:bundleID];
        items[bundleID] = item;
    }
    
    self.myItems = items;

    NSArray* existingTasks = [self.repo tasks];
    for (ZincTask* task in existingTasks) {
        [self associateTaskWithActivityItem:task];
    }
    
    [self update];
}

- (void) monitoringDidStop
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) associateTaskWithActivityItem:(ZincTask*)task
{
    if (![task.taskDescriptor.resource isZincBundleResource]) return;
    if (![task.taskDescriptor.action isEqualToString:ZincTaskActionUpdate]) return;
    
    NSString* taskBundleID = [task.resource zincBundleID];
    
    if (![self.bundleIDs containsObject:taskBundleID]) return;
    if ([self.repo stateForBundleWithID:taskBundleID] == ZincBundleStateAvailable) return;
    
    ZincBundleAvailabilityMonitorItem* item = (self.myItems)[taskBundleID];
    item.task = task;
}

- (void) taskAdded:(NSNotification*)note
{
    ZincTask* task = [note userInfo][ZincRepoTaskNotificationTaskKey];
    [self associateTaskWithActivityItem:task];
}

@end


@implementation ZincBundleAvailabilityMonitorItem

- (id) initWithMonitor:(ZincBundleAvailabilityMonitor*)monitor bundleID:(NSString*)bundleID
{
    self = [super initWithActivityMonitor:monitor];
    if (self) {
        _bundleID = bundleID;
    }
    return self;
}

- (void) update
{
    if ([self isFinished]) return;

    ZincBundleAvailabilityMonitor* bundleMon = (ZincBundleAvailabilityMonitor*)self.monitor;
    ZincBundleState state = [bundleMon.repo stateForBundleWithID:self.bundleID];

    if (state == ZincBundleStateAvailable) {
        [self finish];
    }
}

@end