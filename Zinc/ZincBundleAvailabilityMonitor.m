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
#import "ZincRepo+Private.h"
#import "ZincProgress+Private.h"
#import "ZincTaskActions.h"


@interface ZincBundleAvailabilityMonitor ()
@property (nonatomic, readwrite, copy) NSArray* bundleIDs;
@property (nonatomic, strong) NSMutableDictionary* myItems;
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

- (void)dealloc
{
    [self stopMonitoring];
}

- (NSArray*) items
{
    return [self.myItems allValues];
}

- (BOOL)hasDesiredVersionForBundleID:(NSString*)bundleID
{
    if (self.requireCatalogVersion) {
        return [self.repo hasCurrentDistroVersionForBundleID:bundleID];
    }
    return [self.repo stateForBundleWithID:bundleID] == ZincBundleStateAvailable;
}

- (ZincBundleAvailabilityMonitorItem*) itemForBundleID:(NSString*)bundleID
{
    return (self.myItems)[bundleID];
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
    // Check if it's a bundle update task
    if (![task.taskDescriptor.resource isZincBundleResource]) return;
    if (![task.taskDescriptor.action isEqualToString:ZincTaskActionUpdate]) return;

    // Check if it's one of the bundles were interested in
    NSString* taskBundleID = [task.resource zincBundleID];
    if (![self.bundleIDs containsObject:taskBundleID]) return;

    // Check if its going to be updating the right version
    if (self.requireCatalogVersion) {
        if ([self.repo hasCurrentDistroVersionForBundleID:taskBundleID]) return;
        if ([task.taskDescriptor.resource zincBundleVersion] != [self.repo currentDistroVersionForBundleID:taskBundleID]) return;
    } else {
        if ([self.repo stateForBundleWithID:taskBundleID] == ZincBundleStateAvailable) return;
    }

    ZincBundleAvailabilityMonitorItem* item = (self.myItems)[taskBundleID];
    item.operation = task;
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
        [self initializeProgress];
    }
    return self;
}

- (void) initializeProgress
{
    [self updateCurrentProgressValue:0 maxProgressValue:LONG_LONG_MAX];
}

- (void) update
{
    if ([self isFinished]) return;

    ZincBundleAvailabilityMonitor* bundleMon = (ZincBundleAvailabilityMonitor*)self.monitor;
    const BOOL hasDesiredVersion = [bundleMon hasDesiredVersionForBundleID:self.bundleID];

    if (hasDesiredVersion) {
        
        [self finish];

    } else if (self.operation != nil) {

        if ([self.operation isFinished]) {

            // the task finished, but the desired version is still not
            // available. nil out the task and wait for another one
            self.operation = nil;
            [self initializeProgress];

        } else {

            // the operation is valid, use it's progress
            [self updateFromProgress:self.operation];
        }
    }
}

@end