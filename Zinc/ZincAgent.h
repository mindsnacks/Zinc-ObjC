//
//  ZincRepoAgent.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/30/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZincRepo;
@class ZincDownloadPolicy;
@class KSReachability;

@interface ZincAgent : NSObject

#pragma mark -

+ (instancetype) agentForRepo:(ZincRepo*)repo;

@property (nonatomic, strong, readonly) ZincRepo *repo;
@property (nonatomic, strong, readonly) KSReachability *reachability;


#pragma mark -
#pragma mark Refresh

/**
 * Manually trigger refresh of sources and bundles.
 */
- (void) refresh;

/**
 * Manually trigger refresh of sources and bundles, with completion block.
 */
- (void) refreshWithCompletion:(dispatch_block_t)completion;

/**
 * Interval at which catalogs are updated and automatic clone tasks started.
 */
@property (nonatomic, assign) NSTimeInterval autoRefreshInterval;


- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion;


/**
 @discussion Update all bundles
 */
- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion;



#pragma mark -
#pragma mark Download Policy

/**
 */
@property (nonatomic, strong, readonly) ZincDownloadPolicy* downloadPolicy;

- (BOOL) doesPolicyAllowDownloadForBundleID:(NSString*)bundleID;

@end
