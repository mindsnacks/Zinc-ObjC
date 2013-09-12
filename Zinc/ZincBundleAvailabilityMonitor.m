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

- (id)initWithRepo:(ZincRepo*)repo requests:(NSArray*)items
{
    NSParameterAssert(repo);
    NSParameterAssert(items);
    self = [super init];
    if (self) {
        _repo = repo;
        _itemsByBundleID = [[NSMutableDictionary alloc] init];
        for (ZincBundleAvailabilityMonitorRequest* req in items) {
            [self addBundleAvailabilityMonitorItemForRequest:req];
        }
    }
    return self;
}

- (id)initWithRepo:(ZincRepo*)repo bundleIDs:(NSArray*)bundleIDs requireCatalogVersion:(BOOL)requireCatalogVersion
{
    NSMutableArray* requests = [[NSMutableArray alloc] initWithCapacity:[bundleIDs count]];
    for (NSString* bundleID in bundleIDs) {
        [requests addObject:[ZincBundleAvailabilityMonitorRequest requestForBundleID:bundleID requireCatalogVersion:requireCatalogVersion]];
    }
    return [self initWithRepo:repo requests:requests];
}

- (id)initWithRepo:(ZincRepo*)repo bundleIDs:(NSArray*)bundleIDs
{
    return [self initWithRepo:repo bundleIDs:bundleIDs requireCatalogVersion:NO];
}

- (id)init
{
    return [self initWithRepo:nil requests:nil];
}

- (void) dealloc
{
    [self stopMonitoring];
}

- (void) addBundleAvailabilityMonitorItemForRequest:(ZincBundleAvailabilityMonitorRequest*)request;
{
    ZincBundleAvailabilityMonitorActivityItem* item = [[ZincBundleAvailabilityMonitorActivityItem alloc] initWithMonitor:self request:request];
    [super addItem:item];
    self.itemsByBundleID[request.bundleID] = item;
}

- (NSArray*) bundleIDs
{
    return [self.itemsByBundleID allKeys];
}

- (ZincBundleAvailabilityMonitorActivityItem*) activityItemForBundleID:(NSString*)bundleID
{
    return self.itemsByBundleID[bundleID];
}

- (void) monitoringDidStart
{
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
    ZincBundleAvailabilityMonitorActivityItem* item = self.itemsByBundleID[taskBundleID];
    if (item == nil) return;

    // Check if its going to be updating the right version
    if (item.request.requireCatalogVersion) {
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


@implementation ZincBundleAvailabilityMonitorRequest

- (id) initWithBundleID:(NSString*)bundleID requireCatalogVersion:(BOOL)requireCatalogVersion
{
    self = [super init];
    if (self) {
        _bundleID = bundleID;
        _requireCatalogVersion = requireCatalogVersion;
    }
    return self;
}

+ (instancetype) requestForBundleID:(NSString*)bundleID requireCatalogVersion:(BOOL)requireCatalogVersion
{
    return [[self alloc] initWithBundleID:bundleID requireCatalogVersion:requireCatalogVersion];
}

+ (instancetype) requestForBundleID:(NSString*)bundleID
{
    return [self requestForBundleID:bundleID requireCatalogVersion:NO];
}

@end


@implementation ZincBundleAvailabilityMonitorActivityItem

- (id)initWithMonitor:(ZincBundleAvailabilityMonitor *)monitor request:(ZincBundleAvailabilityMonitorRequest *)request
{
    self = [super initWithActivityMonitor:monitor];
    if (self) {
        _request = request;
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
    if (self.request.requireCatalogVersion) {
        return [[self repo] hasCurrentDistroVersionForBundleID:bundleID];
    }
    return [[self repo] stateForBundleWithID:bundleID] == ZincBundleStateAvailable;
}

- (BOOL) hasDesiredBundleVersion
{
    return [self hasDesiredVersionForBundleID:self.request.bundleID];
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