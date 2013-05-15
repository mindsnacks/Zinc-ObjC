//
//  ZincBundleCloneMonitor.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincActivityMonitor.h"
#import "ZincProgress.h"

@class ZincRepo;
@class ZincBundleAvailabilityMonitorItem;

@interface ZincBundleAvailabilityMonitor : ZincActivityMonitor

- (id)initWithRepo:(ZincRepo*)repo bundleIDs:(NSArray*)bundleIDs;

@property (nonatomic, readonly, strong) ZincRepo* repo;
@property (nonatomic, readonly, copy) NSArray* bundleIDs;

#pragma mark -

@property (nonatomic, copy) ZincProgressBlock progressBlock;
@property (nonatomic, copy) ZincCompletionBlock completionBlock;

#pragma mark -

- (ZincBundleAvailabilityMonitorItem*) itemForBundleID:(NSString*)bundleID;

/**
 @discussion Is Key-Value Observable
 */
@property (nonatomic, readonly, assign) float totalProgress;

- (BOOL) isFinished;

@end



@interface ZincBundleAvailabilityMonitorItem : ZincActivityItem

@property (nonatomic, readonly, copy) NSString* bundleID;

@end