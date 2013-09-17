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

- (id)initWithRepo:(ZincRepo*)repo requirements:(NSArray*)items
{
    NSParameterAssert(repo);
    NSParameterAssert(items);
    self = [super init];
    if (self) {
        _repo = repo;
        _itemsByBundleID = [[NSMutableDictionary alloc] init];
        for (ZincBundleAvailabilityRequirement* req in items) {
            [self addBundleAvailabilityMonitorItemForRequest:req];
        }
    }
    return self;
}

- (id)initWithRepo:(ZincRepo*)repo bundleIDs:(NSArray*)bundleIDs versionSpecifier:(ZincBundleVersionSpecifier)versionSpecifier
{
    NSMutableArray* requests = [[NSMutableArray alloc] initWithCapacity:[bundleIDs count]];
    for (NSString* bundleID in bundleIDs) {
        [requests addObject:[ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:versionSpecifier]];
    }
    return [self initWithRepo:repo requirements:requests];
}

- (id)initWithRepo:(ZincRepo*)repo bundleIDs:(NSArray*)bundleIDs
{
    return [self initWithRepo:repo bundleIDs:bundleIDs versionSpecifier:NO];
}

- (id)init
{
    return [self initWithRepo:nil requirements:nil];
}

- (void) dealloc
{
    [self stopMonitoring];
}

- (void) addBundleAvailabilityMonitorItemForRequest:(ZincBundleAvailabilityRequirement*)request;
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
    if (![self.repo bundleResource:task.taskDescriptor.resource satisfiesVersionSpecifier:item.requirement.versionSpecifier]) return;

    item.subject = task;
}

- (void) taskAdded:(NSNotification*)note
{
    ZincTask* task = [note userInfo][ZincRepoTaskNotificationTaskKey];
    [self associateTaskWithActivityItem:task];
}

@end


@implementation ZincBundleAvailabilityRequirement

- (id) initWithBundleID:(NSString*)bundleID versionSpecifier:(ZincBundleVersionSpecifier)versionSpecifier
{
    self = [super init];
    if (self) {
        _bundleID = bundleID;
        _versionSpecifier = versionSpecifier;
    }
    return self;
}

+ (instancetype) requirementForBundleID:(NSString*)bundleID versionSpecifier:(ZincBundleVersionSpecifier)requireCatalogVersion
{
    return [[self alloc] initWithBundleID:bundleID versionSpecifier:requireCatalogVersion];
}

+ (instancetype) requirementForBundleID:(NSString*)bundleID
{
    return [self requirementForBundleID:bundleID versionSpecifier:NO];
}

@end


@implementation ZincBundleAvailabilityMonitorActivityItem

- (id)initWithMonitor:(ZincBundleAvailabilityMonitor *)monitor request:(ZincBundleAvailabilityRequirement *)requirement
{
    self = [super initWithActivityMonitor:monitor];
    if (self) {
        _requirement = requirement;
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
    return [[self repo] hasSpecifiedVersion:self.requirement.versionSpecifier forBundleID:bundleID];
}

- (BOOL) isFinished
{
    return [self hasDesiredVersionForBundleID:self.requirement.bundleID];
}

- (void) update
{
    [super update];

    if ([self.subject isFinished] && ![self isFinished]) {
        self.currentProgressValue = 0;
        self.subject = nil;
    }
}

@end