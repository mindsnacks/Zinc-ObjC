//
//  ZincBundleCloneMonitor.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleAvailabilityMonitor+Private.h"

#import "ZincInternals.h"
#import "ZincActivityMonitor+Private.h"
#import "ZincRepo+Private.h"
#import "ZincProgress+Private.h"
#import "ZincTaskActions.h"


@interface ZincBundleAvailabilityMonitor ()
@property (nonatomic, retain) NSMutableDictionary* itemsByBundleID;
@property (nonatomic, readwrite, copy) NSArray* bundleIDs;
@end


@implementation ZincBundleAvailabilityMonitor

@dynamic bundleIDs;

- (id)initWithRepo:(ZincRepo*)repo
{
    self = [super init];
    if (self) {
        _repo = repo;
        _itemsByBundleID = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [self stopMonitoring];
}

- (NSArray*) bundleIDs
{
    return [self.itemsByBundleID allKeys];
}

- (void) addMonitoredBundleID:(NSString*)bundleID requireCatalogVersion:(BOOL)requireCatalogVersion
{
    if ([self.progress isFinished]) {
        @throw [NSException
                exceptionWithName:NSInternalInconsistencyException
                reason:[NSString stringWithFormat:@"added a monitored bundle ID after monitor has finished"]
                userInfo:nil];

    }

    ZincBundleAvailabilityMonitorItem* item = [[ZincBundleAvailabilityMonitorItem alloc] initWithMonitor:self bundleID:bundleID requireCatalogVersion:requireCatalogVersion];
    [self addItem:item];
    self.itemsByBundleID[bundleID] = item;
}


- (ZincBundleAvailabilityMonitorItem*) itemForBundleID:(NSString*)bundleID
{
    return self.itemsByBundleID[bundleID];
}

- (void) monitoringDidStart
{
    if ([[self items] count] == 0) {
        @throw [NSException
                exceptionWithName:NSInternalInconsistencyException
                reason:[NSString stringWithFormat:@"no bundle ids were added before being started"]
                userInfo:nil];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskAdded:)
                                                 name:ZincRepoTaskAddedNotification
                                               object:self.repo];
    
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
    ZincBundleAvailabilityMonitorItem* item = self.itemsByBundleID[taskBundleID];
    if (item == nil) return;

    // Check if its going to be updating the right version
    if (item.requireCatalogVersion) {
        if ([self.repo hasCurrentDistroVersionForBundleID:taskBundleID]) return;
        if ([task.taskDescriptor.resource zincBundleVersion] != [self.repo currentDistroVersionForBundleID:taskBundleID]) return;
    } else {
        if ([self.repo stateForBundleWithID:taskBundleID] == ZincBundleStateAvailable) return;
    }

    item.operation = task;
}

- (void) taskAdded:(NSNotification*)note
{
    ZincTask* task = [note userInfo][ZincRepoTaskNotificationTaskKey];
    [self associateTaskWithActivityItem:task];
}

@end


@implementation ZincBundleAvailabilityMonitorItem

- (id) initWithMonitor:(ZincBundleAvailabilityMonitor*)monitor bundleID:(NSString*)bundleID requireCatalogVersion:(BOOL)requireCatalogVersion
{
    self = [super initWithActivityMonitor:monitor];
    if (self) {
        _bundleID = bundleID;
        _requireCatalogVersion = requireCatalogVersion;
    }
    return self;
}

- (ZincRepo*) repo
{
    ZincBundleAvailabilityMonitor* bundleMon = (ZincBundleAvailabilityMonitor*)self.monitor;
    return bundleMon.repo;
}

- (BOOL) hasDesiredVersionForBundleID:(NSString*)bundleID
{
    if (self.requireCatalogVersion) {
        return [[self repo] hasCurrentDistroVersionForBundleID:bundleID];
    }
    return [[self repo] stateForBundleWithID:bundleID] == ZincBundleStateAvailable;
}

- (BOOL) hasDesiredBundleVersion
{
    return [self hasDesiredVersionForBundleID:self.bundleID];
}

- (void) update
{
    if ([self isFinished]) return;

    if ([self hasDesiredBundleVersion]) {
        
        [self finish];

    } else if (self.operation != nil) {

        if ([self.operation isFinished]) {

            // the task finished, but the desired version is still not
            // available. nil out the task and wait for another one
            [self updateCurrentProgressValue:0 maxProgressValue:self.operation.maxProgressValue];
            self.operation = nil;
            self.currentProgressValue = 0;

        } else {

            // the operation is valid, use it's progress
            [self updateFromProgress:self.operation];
        }
    }
}

@end