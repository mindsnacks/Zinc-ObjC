//
//  ZincBundleCloneMonitor.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincCompletableActivityMonitor.h"

@class ZincRepo;
@class ZincBundleAvailabilityMonitorItem;

@interface ZincBundleAvailabilityMonitor : ZincCompletableActivityMonitor

- (id)initWithRepo:(ZincRepo*)repo;

@property (nonatomic, readonly, strong) ZincRepo* repo;
@property (nonatomic, readonly) NSArray* bundleIDs;

#pragma mark -

- (void) addMonitoredBundleID:(NSString*)bundleID requireCatalogVersion:(BOOL)requireCatalogVersion;

- (ZincBundleAvailabilityMonitorItem*) itemForBundleID:(NSString*)bundleID;

@end


@interface ZincBundleAvailabilityMonitorItem : ZincActivityItem

@property (nonatomic, readonly, copy) NSString* bundleID;
@property (nonatomic, readonly, assign) BOOL requireCatalogVersion;

@end