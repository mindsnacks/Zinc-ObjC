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


/**
 `ZincAgent`

 This class is part of the *Zinc Public API*.
 */
@interface ZincAgent : NSObject

///---------------------
/// @name Initialization
//----------------------

/**
 Get the `ZincAgent` for the specified repo. This will always return the
 same `ZincAgent` object for the same `ZincRepo`.
 */
+ (instancetype) agentForRepo:(ZincRepo*)repo;

/**
 The `ZincRepo` for this agent.
 */
@property (nonatomic, strong, readonly) ZincRepo *repo;


///--------------
/// @name Refresh
//---------------

/**
 Interval at which catalogs are updated and automatic clone tasks started.
 
 NOTE: is initialized to 0. Must be set to >0 to refresh automatically.
 */
@property (nonatomic, assign) NSTimeInterval autoRefreshInterval;

/**
 * Manually trigger refresh of sources and bundles.
 */
- (void) refresh;

/**
 Manually trigger refresh of sources and bundles, with completion block.
 
 @param completionBlock a block to call when update attempt is finished
 */
- (void) refreshWithCompletion:(dispatch_block_t)completionBlock;

/**
 Refresh all sources. This is the same as calling directly on the Zinc repo.
 
 @param completionBlock a block to call when update attempt is finished
 */
- (void) refreshSourcesWithCompletion:(dispatch_block_t)completionBlock;

/**
 Attempt to update all bundles exactly once.

 @param completionBlock a block to call when update attempt is finished
 */
- (void) refreshBundlesWithCompletion:(dispatch_block_t)completionBlock;

@end