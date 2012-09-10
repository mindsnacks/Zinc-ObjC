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

@property (nonatomic, readonly, retain) ZincRepo* repo;
@property (nonatomic, readonly, retain) NSArray* bundleIDs;

#pragma mark -

@property (nonatomic, copy) ZincProgressBlock progressBlock;
@property (nonatomic, copy) ZincCompletionBlock completionBlock;

#pragma mark -

- (NSArray*) items;
- (ZincBundleAvailabilityMonitorItem*) itemForBundleID:(NSString*)bundleID;

/**
 @discussion Is Key-Value Observable
 */
@property (nonatomic, readonly, assign) float totalProgress;

@end



@interface ZincBundleAvailabilityMonitorItem : NSObject <ZincObservableProgress>

@property (nonatomic, readonly, assign) ZincBundleAvailabilityMonitor* monitor;
@property (nonatomic, readonly, assign) NSString* bundleID;

@end