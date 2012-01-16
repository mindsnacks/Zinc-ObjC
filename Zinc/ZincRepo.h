//
//  ZCBundleManager.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"

#define kZincRepoDefaultNetworkOperationCount (5)
#define kZincRepoDefaultAutoRefreshInterval (10)
#define kZincRepoDefaultCacheCount (20)

@protocol ZincRepoDelegate;
@class ZincBundle;

@interface ZincRepo : NSObject

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL error:(NSError**)outError;
+ (ZincRepo*) repoWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue error:(NSError**)outError;

@property (nonatomic, assign) id<ZincRepoDelegate> delegate;
@property (nonatomic, retain, readonly) NSURL* url;

@property (nonatomic, assign) NSTimeInterval refreshInterval;

#pragma mark Sources

- (void) addSourceURL:(NSURL*)url;
- (void) removeSourceURL:(NSURL*)url;

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion;

#pragma mark Bundles

- (void) beginTrackingBundleWithId:(NSString*)bundleId distribution:(NSString*)distro;
- (void) stopTrackingBundleWithId:(NSString*)bundleId;

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion;

- (ZincBundle*) bundleWithId:(NSString*)bundleId;

#pragma mark Tasks

@property (readonly) NSArray* tasks;

- (void) suspendAllTasks;
- (void) resumeAllTasks;
           
@end


@protocol ZincRepoDelegate <NSObject>

- (void) zincRepo:(ZincRepo*)repo didEncounterError:(NSError*)error;

@end
