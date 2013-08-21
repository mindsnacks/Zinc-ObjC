//
//  ZCBundleManager.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZincGlobals.h"

@protocol ZincRepoEventListener;
@class ZincBundle;
@class ZincBundleTrackingRequest;
@class ZincEvent;
@class ZincTaskRef;

/**
 `ZincRepo`
 
 ## Usage Notes
 
 - All `ZincRepo` objects start suspended. After obtaining a `ZincRepo` object, you must call `-resumeAllTasks`
 */
@interface ZincRepo : NSObject

///---------------------
/// @name Initialization
//----------------------

/**
 Create a new `ZincRepo` object with the given fileURL. This is the standard way to obtain a `ZincRepo` object.
 @param fileURL a local file URL
 @param outError error output param
 */
+ (ZincRepo*) repoWithURL:(NSURL*)fileURL error:(NSError**)outError;


+ (ZincRepo*) repoWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue error:(NSError**)outError;

/**
 The Zinc repo may need to perform some initialization tasks. This property be `NO` until these initialization tasks are performed, and `YES` aferwards.
 */
@property (nonatomic, assign, readonly) BOOL isInitialized;

/**
 Block until initialization is complete.
 */
- (void) waitForInitialization;

/**
 Returns an task reference (`ZincTaskRef`) for any initialization tasks that need to be done. Returns nil if no initialization is required. See the `ZincTaskRef` documentation for usage.
 */
- (ZincTaskRef*) taskRefForInitialization;

///--------------------------------
/// @name Getting basic information
///--------------------------------

/**
 The local file URL of the `ZincRepo`
 */
@property (nonatomic, strong, readonly) NSURL* url;


/**
 Whether their is a valid Zinc repo at the given URL.
 @param fileURL a local file URL
 */
+ (BOOL) repoExistsAtURL:(NSURL*)fileURL;


///--------------------
/// @name Configuration
///--------------------

/**
 Set the event listender. See documentation for `ZincRepoEventListener`.
 */
@property (nonatomic, weak) id<ZincRepoEventListener> eventListener;

/**
 Set the default thread priority for all Zinc operations. It is initially set to `0.5`, which is the same as the default thread priority for `NSOperation`.
 @param defaultThreadPriority New default thread priorty, between 0.0 and 1.0
 */
+ (void) setDefaultThreadPriority:(double)defaultThreadPriority;

///------------------
/// @name Maintenance
///------------------

/**
 * Perform cleanup tasks. Runs automatically at repo initialization, but can be queued manually as well.
 */
- (void) cleanWithCompletion:(dispatch_block_t)completion;

///-----------------------
/// @name Managing Sources
///-----------------------

/**
 Add a new source URL, if it does not already exist.
 */
- (void) addSourceURL:(NSURL*)url;

/**
 Remove a source URL.
 @param url The URL to remove. If the source URL is not registered, this does nothing.
 */
- (void) removeSourceURL:(NSURL*)url;

/**
 Return a copy of all registered source URLs.
 */
- (NSSet*) sourceURLs;

/**
 Refresh local copies of Zinc catalogs from all registered source URLs. This will attempt to refresh each source only once, and may fail due to connectivity issues. To refresh sources more automatically, see `ZincAgent`.
 @param completion A block to call once all sources have been attempted to be refreshed. May be nil.
 */
- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion;


#pragma mark -
#pragma mark External Bundles

- (BOOL) registerExternalBundleWithManifestPath:(NSString*)manifestPath bundleRootPath:(NSString*)rootPath error:(NSError**)outError;


#pragma mark -
#pragma mark Tracking Remote Bundles

- (void) beginTrackingBundleWithRequest:(ZincBundleTrackingRequest*)req;
- (void) beginTrackingBundleWithID:(NSString*)bundleID distribution:(NSString*)distro;
- (void) beginTrackingBundleWithID:(NSString*)bundleID distribution:(NSString*)distro flavor:(NSString*)flavor;

- (void) stopTrackingBundleWithID:(NSString*)bundleID;

- (NSSet*) trackedBundleIDs;


#pragma mark -
#pragma mark Updating Bundles

/**
 * Manually update a bundle. Currently ignores downloadPolicy and will update regardless of connectivity.
 */
- (void) updateBundleWithID:(NSString*)bundleID completionBlock:(ZincCompletionBlock)completion;
- (ZincTaskRef*) updateBundleWithID:(NSString*)bundleID;



#pragma mark -
#pragma mark Loading Bundles

/**
 @discussion Main, offical way to get a bundle of files. Will raise an exception if the repo is not initialized
 */
- (ZincBundle*) bundleWithID:(NSString*)bundleID;

- (ZincBundleState) stateForBundleWithID:(NSString*)bundleID;


#pragma mark -
#pragma mark Tasks

@property (readonly) NSArray* tasks;

- (void) suspendAllTasks;
- (void) suspendAllTasksAndWaitExecutingTasksToComplete;
- (void) resumeAllTasks;
- (BOOL) isSuspended;
       
@end


#pragma mark -

@protocol ZincRepoEventListener <NSObject>

- (void) zincRepo:(ZincRepo*)repo didReceiveEvent:(ZincEvent*)event;

@end




// -- Bundle Notifications
extern NSString* const ZincRepoBundleStatusChangeNotification;
extern NSString* const ZincRepoBundleDidBeginTrackingNotification;
extern NSString* const ZincRepoBundleWillStopTrackingNotification;
extern NSString* const ZincRepoBundleWillDeleteNotification;

// -- Bundle Notification UserInfo Keys
extern NSString* const ZincRepoBundleChangeNotificationBundleIDKey;
extern NSString* const ZincRepoBundleChangeNotifiationStatusKey;

// -- Task Notifications
extern NSString* const ZincRepoTaskAddedNotification;
extern NSString* const ZincRepoTaskFinishedNotification;

// -- Task Notification UserInfo Keys
extern NSString* const ZincRepoTaskNotificationTaskKey;




