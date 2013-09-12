//
//  ZincBundleCloneMonitor.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincCompletableActivityMonitor.h"

@class ZincRepo;
@class ZincBundleAvailabilityMonitorActivityItem;

@interface ZincBundleAvailabilityMonitor : ZincCompletableActivityMonitor

/**
 Designated Initializer
 */
- (id)initWithRepo:(ZincRepo*)repo requests:(NSArray*)requests;

/**
 @param requireCatalogVersion this is used for all bundleIDs
 */
- (id)initWithRepo:(ZincRepo*)repo bundleIDs:(NSArray*)bundleIDs requireCatalogVersion:(BOOL)requireCatalogVersion;

/**
 Defaults `requireCatalogVersion` to `NO`
 */
- (id)initWithRepo:(ZincRepo*)repo bundleIDs:(NSArray*)bundleIDs;

@property (nonatomic, readonly, strong) ZincRepo* repo;
@property (nonatomic, readonly) NSArray* bundleIDs;

#pragma mark -

- (ZincBundleAvailabilityMonitorActivityItem*) activityItemForBundleID:(NSString*)bundleID;

@end


@interface ZincBundleAvailabilityMonitorRequest : NSObject

@property (nonatomic, readonly, copy) NSString* bundleID;
@property (nonatomic, readonly, assign) BOOL requireCatalogVersion;

- (id) initWithBundleID:(NSString*)bundleID requireCatalogVersion:(BOOL)requireCatalogVersion;

+ (instancetype) requestForBundleID:(NSString*)bundleID requireCatalogVersion:(BOOL)requireCatalogVersion;

+ (instancetype) requestForBundleID:(NSString*)bundleID;

@end


@interface ZincBundleAvailabilityMonitorActivityItem : ZincActivityItem

@property (nonatomic, retain, readonly) ZincBundleAvailabilityMonitorRequest* request;

@end
