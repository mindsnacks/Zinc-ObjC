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

typedef enum {
    ZincBundleStateNone      = 0,
    ZincBundleStateCloning   = 1,
    ZincBundleStateAvailable = 2,
    ZincBundleStateDeleting  = 3,
} ZincBundleState;

static NSString* ZincBundleStateName[] = {
    @"None",
    @"Cloning",
    @"Available",
    @"Deleting",
};

extern NSString* const ZincRepoBundleChangeNotifiationBundleIdKey;
extern NSString* const ZincRepoBundleChangeNotifiationStatusKey;

extern NSString* const ZincRepoBundleStatusChangeNotification;
extern NSString* const ZincRepoBundleDidBeginTrackingNotification;
extern NSString* const ZincRepoBundleWillStopTrackingNotification;
extern NSString* const ZincRepoBundleWillDeleteNotification;

extern NSString* const ZincRepoBundleCloneProgressNotification;
extern NSString* const ZincRepoBundleCloneProgressKey;

@protocol ZincRepoDelegate;
@class ZincManifest;
@class ZincBundle;
@class ZincEvent;
@class ZincBundleTrackingRequest;
@class ZincDownloadPolicy;

@interface ZincRepo : NSObject

// !!!: Note all repos start suspended. After obtaining a repo object,
// you must all [repo resumeAllTasks]

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL error:(NSError**)outError;
+ (ZincRepo*) repoWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue error:(NSError**)outError;

+ (BOOL) repoExistsAtURL:(NSURL*)fileURL;

@property (nonatomic, assign) id<ZincRepoDelegate> delegate;
@property (nonatomic, retain, readonly) NSURL* url;

/**
 @discussion Interval at which catalogs are updated and automatic clone tasks started.
 */
@property (nonatomic, assign) NSTimeInterval refreshInterval;

/**
 @discussion default is YES
 */
@property (atomic, assign) BOOL executeTasksInBackgroundEnabled;

/**
 @discussion Setting to NO disables all automatic updates. Default is YES.
 */
@property (atomic, assign) BOOL automaticBundleUpdatesEnabled;

/**
 */
@property (nonatomic, retain, readonly) ZincDownloadPolicy* downloadPolicy;

#pragma mark Sources

- (void) addSourceURL:(NSURL*)url;
- (void) removeSourceURL:(NSURL*)url;

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion;

#pragma mark Bundles

- (void) bootstrapBundleWithRequest:(ZincBundleTrackingRequest*)req fromDir:(NSString*)dir completionBlock:(ZincCompletionBlock)completion;
- (void) bootstrapBundleWithId:(NSString*)bundleId fromDir:(NSString*)dir completionBlock:(ZincCompletionBlock)completion;
- (void) bootstrapBundleWithId:(NSString*)bundleId flavor:(NSString*)flavor fromDir:(NSString*)dir completionBlock:(ZincCompletionBlock)completion;

- (void) beginTrackingBundleWithRequest:(ZincBundleTrackingRequest*)req;
- (void) beginTrackingBundleWithId:(NSString*)bundleId distribution:(NSString*)distro automaticallyUpdate:(BOOL)autoUpdate;
- (void) beginTrackingBundleWithId:(NSString*)bundleId distribution:(NSString*)distro flavor:(NSString*)flavor automaticallyUpdate:(BOOL)autoUpdate;

- (void) updateBundleWithId:(NSString*)bundleId completionBlock:(ZincCompletionBlock)completion;

- (void) stopTrackingBundleWithId:(NSString*)bundleId;

- (NSSet*) trackedBundleIds;

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion;

- (ZincBundleState) stateForBundleWithId:(NSString*)bundleId;

- (ZincBundle*) bundleWithId:(NSString*)bundleId;

//- (void) setPriority:(NSOperationQueuePriority)priority forBundleWithId:(NSString*)bundleId;

// NOTE: this may be removed soon
- (void) waitForAllBootstrapTasks;

#pragma mark Tasks

@property (readonly) NSArray* tasks;

- (void) suspendAllTasks;
- (void) resumeAllTasks;
- (BOOL) isSuspended;

#pragma mark Utility

+ (void)setDefaultThreadPriority:(double)defaultThreadPriority;
       
@end


@protocol ZincRepoDelegate <NSObject>

- (void) zincRepo:(ZincRepo*)repo didReceiveEvent:(ZincEvent*)event;

@end
