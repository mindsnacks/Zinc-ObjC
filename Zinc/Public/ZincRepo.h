//
//  ZincRepo.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"

@protocol ZincRepoEventListener;
@class ZincBundle;
@class ZincBundleTrackingRequest;
@class ZincDownloadPolicy;
@class ZincEvent;
@class ZincTaskRef;
@class KSReachability;

/**
 `ZincRepo`
 
 This class is part of the *Zinc Public API*.
 
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
+ (instancetype) repoWithURL:(NSURL*)fileURL error:(NSError**)outError;

/**
 Create a new `ZincRepo` object with the given fileURL. This allows for a custom networkQueue

 @param fileURL a local file URL
 @param networkQueue the `NSOperationQueue` to use for network operations
 @param outError error output param
 */
+ (instancetype) repoWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue error:(NSError**)outError;

@property (nonatomic, strong, readonly) KSReachability *reachability;

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
- (ZincTaskRef*) initializationTaskRef;

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

/**
 Returns a set of all downloaded catalog files
 */
- (NSSet<NSString *> *)downloadedCatalogIDs;

/**
 Returns a set of all downloaded bundle files
 */
- (NSSet<NSString *> *)downloadedBundleIDs;

///---------------------------
/// @name Working with Bundles
///---------------------------

/**
 Begin tracking a bundle.
 
 @param req The bundle tracking request
 */
- (void) beginTrackingBundleWithRequest:(ZincBundleTrackingRequest*)req;

/**
 Convenience method for tracking a bundle. Assumes flavor is nil.
 
 @param bundleID The ID of the bundle
 @param distro The distro to track
 */
- (void) beginTrackingBundleWithID:(NSString*)bundleID distribution:(NSString*)distro;

/**
 Convenience method for tracking a bundle

 @param bundleID The ID of the bundle
 @param distro The distro to track
 @param flavor The flavor to track
 */
- (void) beginTrackingBundleWithID:(NSString*)bundleID distribution:(NSString*)distro flavor:(NSString*)flavor;

/**
 Updates the tracked distribution while leaving the tracked flavor intact.
 */
- (void) updateTrackedDistributionForBundleWithID:(NSString*)bundleID distribution:(NSString*)distro;

/**
 Stop tracking a bundle.
 */
- (void) stopTrackingBundleWithID:(NSString*)bundleID;

/**
 Get all currently tracking bundles.
 */
- (NSSet*) trackedBundleIDs;

/**
 Get the tracked distro for a bundleID
 */
- (NSString*) trackedDistributionForBundleID:(NSString*)bundleID;

/**
 Manually update a bundle. Currently ignores downloadPolicy and will update regardless of connectivity.
 
 @param bundleID The ID of the bundle to update.
 @param completion A block to be called once the update attempt completes.
 */
- (void) updateBundleWithID:(NSString*)bundleID completionBlock:(ZincCompletionBlock)completion;

/**
 Manually update a bundle. Currently ignores downloadPolicy and will update regardless of connectivity.
 
 This is similar to `updateBundleWithID:completionBlock:` except it returns a `ZincTaskRef` instead of the completion block.
 */
- (ZincTaskRef*) updateBundleWithID:(NSString*)bundleID;

/**
 Obtain a Zinc bundle. This will raise an exception if the repo is not initialized

 @param bundleID The ID of the bundle.
 @param versionSpecifier The version specifier.

*/
- (ZincBundle*) bundleWithID:(NSString*)bundleID versionSpecifier:(ZincBundleVersionSpecifier)versonSpecifier;

/**
 Obtain a Zinc bundle with the `ZincBundleVersionSpecifierDefault`.
 
 @param bundleID The ID of the bundle.
 */
- (ZincBundle*) bundleWithID:(NSString*)bundleID;

/**
 Get the state of a bundle.

 @param bundleID The ID of the bundle
 @param versionSpec The version specifier
 */
- (ZincBundleState) stateForBundleWithID:(NSString*)bundleID versionSpecifier:(ZincBundleVersionSpecifier)versionSpec;

/**
 Get the state of a bundle.
 
 @param bundleID The ID of the bundle
 @default versionSpec ZincBundleVersionSpecifierDefault
 */
- (ZincBundleState) stateForBundleWithID:(NSString*)bundleID;

/**
 @param bundleID the bundleID
 @param versionSpec the versionSpec
 @return `YES` if the current version of the bundle satisfies the version spec, `NO` otherwise
 */
- (BOOL) hasSpecifiedVersion:(ZincBundleVersionSpecifier)versionSpec forBundleID:(NSString*)bundleID;

/**
 Register an external bundle.
 
 TODO: document this feature with more detail
 
 @param manifestPath The path to the manifest for the bundle
 @param bundleRootPath The path of the bundles files
 @param outError Error output parameter
 */
- (BOOL) registerExternalBundleWithManifestPath:(NSString*)manifestPath bundleRootPath:(NSString*)bundleRootPath error:(NSError**)outError;

/**
 Purges bundles with the given prefix when the total sum of the size of the bundles reaches the limit.
 The bundles are deleted, their associated manifest files deleted, and completely wiped from the repo.json file.
 */
- (void)setBundleSizeLimitInMB:(float)sizeLimitInMB
          forBundlesWithPrefix:(NSString *)prefix;

///----------------------
/// @name Task Management
///----------------------

/**
 Returns a copy of all active tasks within this repo.
 */
@property (readonly) NSArray* tasks;

/**
 Suspend (or pause) all *pending* tasks in this repo. Tasks in process will run to completion.
 */
- (void) suspendAllTasks;

/**
 Suspend all *pending* tasks, and block until all *executing tasks are completed.
 */
- (void) suspendAllTasksAndWaitExecutingTasksToComplete;

/**
 Resume all tasks if the repo is suspended.
 */
- (void) resumeAllTasks;

/**
 Returns `YES` if the repo is suspended, `NO` otherwise.
 */
- (BOOL) isSuspended;

///----------------------
/// @name Download Policy
///----------------------

@property (nonatomic, strong, readonly) ZincDownloadPolicy* downloadPolicy;

- (BOOL) doesPolicyAllowDownloadForBundleID:(NSString*)bundleID;
       
@end


///-------------------
/// @name Notifcations
///-------------------

extern NSString* const ZincRepoReachabilityChangedNotification;

/**
 Posted when a bundle's status changes
 
 The `useInfo` dict will contain the key `ZincRepoBundleChangeNotificationBundleIDKey` whose value will be the bundle ID.
 */
extern NSString* const ZincRepoBundleStatusChangeNotification;

/**
 Posted when a bundle begins tracking.
 
 The `useInfo` dict will contain the key `ZincRepoBundleChangeNotificationBundleIDKey` whose value will be the bundle ID.
 */
extern NSString* const ZincRepoBundleDidBeginTrackingNotification;

/**
 Posted when a bundle is no longer being tracked.
 
 The `useInfo` dict will contain the key `ZincRepoBundleChangeNotificationBundleIDKey` whose value will be the bundle ID.
 */
extern NSString* const ZincRepoBundleWillStopTrackingNotification;

/**
 Posted when a bundle will be deleted.
 */
extern NSString* const ZincRepoBundleWillDeleteNotification;

extern NSString* const ZincRepoBundleChangeNotificationBundleIDKey;
extern NSString* const ZincRepoBundleChangeNotifiationStatusKey;

/**
 Posted when a task is added in this repo.
 
 The `userInfo` dict will contain the `ZincRepoTaskNotificationTaskKey` whose value will be the task.
 */
extern NSString* const ZincRepoTaskAddedNotification;

/**
 Posted when a task finishes in this repo.
 
 The `userInfo` dict will contain the `ZincRepoTaskNotificationTaskKey` whose value will be the task.
 */
extern NSString* const ZincRepoTaskFinishedNotification;

extern NSString* const ZincRepoTaskNotificationTaskKey;


/**
 `ZincRepoEventListener`
 */
@protocol ZincRepoEventListener <NSObject>

/**
 Called whenever an event occurs in the ZincRepo
 
 @param repo The repo
 @param event The event
 */
- (void) zincRepo:(ZincRepo*)repo didReceiveEvent:(ZincEvent*)event;

@end
