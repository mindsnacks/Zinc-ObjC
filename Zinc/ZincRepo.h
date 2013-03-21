//
//  ZCBundleManager.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"

#define kZincRepoDefaultObjectDownloadCount (5)
#define kZincRepoDefaultNetworkOperationCount (kZincRepoDefaultObjectDownloadCount*2)
#define kZincRepoDefaultAutoRefreshInterval (120)
#define kZincRepoDefaultCacheCount (20)

typedef enum {
    ZincBundleStateNone      = 0,
    ZincBundleStateCloning   = 1,
    ZincBundleStateAvailable = 2,
    ZincBundleStateDeleting  = 3,
} ZincBundleState;

extern NSString* const ZincBundleStateName[];

extern ZincBundleState ZincBundleStateFromName(NSString* name);

// -- Bundle Notifications
extern NSString* const ZincRepoBundleStatusChangeNotification;
extern NSString* const ZincRepoBundleDidBeginTrackingNotification;
extern NSString* const ZincRepoBundleWillStopTrackingNotification;
extern NSString* const ZincRepoBundleWillDeleteNotification;

// -- Bundle Notification UserInfo Keys
extern NSString* const ZincRepoBundleChangeNotificationBundleIdKey;
extern NSString* const ZincRepoBundleChangeNotifiationStatusKey;

// -- Task Notifications
extern NSString* const ZincRepoTaskAddedNotification;
extern NSString* const ZincRepoTaskFinishedNotification;

// -- Task Notification UserInfo Keys
extern NSString* const ZincRepoTaskNotificationTaskKey;

@protocol ZincRepoDelegate;
@class ZincManifest;
@class ZincBundle;
@class ZincEvent;
@class ZincBundleTrackingRequest;
@class ZincDownloadPolicy;
@class ZincTaskRef;

@interface ZincRepo : NSObject

// !!!: Note all repos start suspended. After obtaining a repo object,
// you must all [repo resumeAllTasks]

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL error:(NSError**)outError;
+ (ZincRepo*) repoWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue error:(NSError**)outError;

+ (BOOL) repoExistsAtURL:(NSURL*)fileURL;

@property (nonatomic, assign) id<ZincRepoDelegate> delegate;
@property (nonatomic, retain, readonly) NSURL* url;

// ----------------------------------------------------------------------------
#pragma mark Initialization

/**
 @discussion The repo may need to perform some initialization tasks. This will 
    be NO until they are performed.
 */
@property (nonatomic, assign, readonly) BOOL isInitialized;

/**
 @discussion Block until initialization is complete.
 */
- (void) waitForInitialization;

/**
 @discussion Returns an task reference for any initialization tasks that need 
    to be done. Returns nil if no initialization is required.
 */
- (ZincTaskRef*) taskRefForInitialization;

// ----------------------------------------------------------------------------
#pragma mark -

/**
 @discussion Manually trigger refresh of sources and bundles.
 */
- (void) refresh;

/**
 @discussion Manually trigger refresh of sources and bundles, with completion block.
 */
- (void) refreshWithCompletion:(dispatch_block_t)completion;

/**
 @discussion Interval at which catalogs are updated and automatic clone tasks started.
 */
@property (nonatomic, assign) NSTimeInterval autoRefreshInterval;

/**
 @discussion default is YES
 */
@property (atomic, assign) BOOL executeTasksInBackgroundEnabled;

/**
 */
@property (nonatomic, retain, readonly) ZincDownloadPolicy* downloadPolicy;

// ----------------------------------------------------------------------------
#pragma mark Sources

- (void) addSourceURL:(NSURL*)url;
- (void) removeSourceURL:(NSURL*)url;
- (NSSet*) sourceURLs;

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion;

// ----------------------------------------------------------------------------
#pragma mark External Bundles

- (BOOL) registerExternalBundleWithManifestPath:(NSString*)manifestPath bundleRootPath:(NSString*)rootPath error:(NSError**)outError;

// ----------------------------------------------------------------------------
#pragma mark Tracking Remote Bundles

- (void) beginTrackingBundleWithRequest:(ZincBundleTrackingRequest*)req;
- (void) beginTrackingBundleWithId:(NSString*)bundleId distribution:(NSString*)distro automaticallyUpdate:(BOOL)autoUpdate;
- (void) beginTrackingBundleWithId:(NSString*)bundleId distribution:(NSString*)distro flavor:(NSString*)flavor automaticallyUpdate:(BOOL)autoUpdate;

- (void) stopTrackingBundleWithId:(NSString*)bundleId;

- (NSSet*) trackedBundleIds;

// ----------------------------------------------------------------------------
#pragma mark mark Updating Bundles

/**
 @discussion Manually update a bundle. Currently ignores downloadPolicy and 
 will update regardles of connectivity.
 */
- (void) updateBundleWithID:(NSString*)bundleID completionBlock:(ZincCompletionBlock)completion;
- (ZincTaskRef*) updateBundleWithID:(NSString*)bundleID;

/**
 @discussion Update all bundles.
 */
- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion;

- (BOOL) doesPolicyAllowDownloadForBundleID:(NSString*)bundleID;

// ----------------------------------------------------------------------------
#pragma mark -

/**
 @discussion Main, offical way to get a bundle of files. Will raise an 
    exception if the repo is not initialized.
 */
- (ZincBundle*) bundleWithId:(NSString*)bundleId;

- (ZincBundleState) stateForBundleWithId:(NSString*)bundleId;

// ----------------------------------------------------------------------------
#pragma mark Tasks

@property (readonly) NSArray* tasks;

- (void) suspendAllTasks;
- (void) suspendAllTasksAndWaitExecutingTasksToComplete;
- (void) resumeAllTasks;
- (BOOL) isSuspended;

// ----------------------------------------------------------------------------
#pragma mark Utility

+ (void)setDefaultThreadPriority:(double)defaultThreadPriority;

/**
 @discussion Perform cleanup tasks. Runs automatically at repo initialization, 
 but can be queued manually as well.
 */
- (void)cleanWithCompletion:(dispatch_block_t)completion;
       
@end

// ----------------------------------------------------------------------------

@protocol ZincRepoDelegate <NSObject>

- (void) zincRepo:(ZincRepo*)repo didReceiveEvent:(ZincEvent*)event;

@end
