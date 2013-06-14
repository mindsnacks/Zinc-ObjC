//
//  ZCBundleManager.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"



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

@protocol ZincRepoDelegate;
@class ZincManifest;
@class ZincBundle;
@class ZincEvent;
@class ZincBundleTrackingRequest;
@class ZincDownloadPolicy;
@class ZincTaskRef;


#pragma mark -

@interface ZincRepo : NSObject

@property (nonatomic, weak) id<ZincRepoDelegate> delegate;
@property (nonatomic, strong, readonly) NSURL* url;

// !!!: Note all repos start suspended. After obtaining a repo object,
// you must all [repo resumeAllTasks]

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL error:(NSError**)outError;
+ (ZincRepo*) repoWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue error:(NSError**)outError;

+ (BOOL) repoExistsAtURL:(NSURL*)fileURL;


#pragma mark -
#pragma mark Initialization

/**
 @discussion The repo may need to perform some initialization tasks. This will be NO until they are performed.
 */
@property (nonatomic, assign, readonly) BOOL isInitialized;

/**
 @discussion Block until initialization is complete.
 */
- (void) waitForInitialization;

/**
 @discussion Returns an task reference for any initialization tasks that need to be done. Returns nil if no initialization is required.
 */
- (ZincTaskRef*) taskRefForInitialization;


#pragma mark -
#pragma mark Configuration

+ (void)setDefaultThreadPriority:(double)defaultThreadPriority;



#pragma mark -
#pragma mark Refresh

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
 @discussion Perform cleanup tasks. Runs automatically at repo initialization, but can be queued manually as well.
 */
- (void)cleanWithCompletion:(dispatch_block_t)completion;


#pragma mark -
#pragma mark Sources

- (void) addSourceURL:(NSURL*)url;
- (void) removeSourceURL:(NSURL*)url;
- (NSSet*) sourceURLs;

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion;


#pragma mark -
#pragma mark External Bundles

- (BOOL) registerExternalBundleWithManifestPath:(NSString*)manifestPath bundleRootPath:(NSString*)rootPath error:(NSError**)outError;


#pragma mark -
#pragma mark Tracking Remote Bundles

- (void) beginTrackingBundleWithRequest:(ZincBundleTrackingRequest*)req;
- (void) beginTrackingBundleWithID:(NSString*)bundleID distribution:(NSString*)distro automaticallyUpdate:(BOOL)autoUpdate;
- (void) beginTrackingBundleWithID:(NSString*)bundleID distribution:(NSString*)distro flavor:(NSString*)flavor automaticallyUpdate:(BOOL)autoUpdate;

- (void) stopTrackingBundleWithID:(NSString*)bundleID;

- (NSSet*) trackedBundleIDs;


#pragma mark -
#pragma mark Updating Bundles

/**
 @discussion Manually update a bundle. Currently ignores downloadPolicy and will update regardles
 of connectivity.
 */
- (void) updateBundleWithID:(NSString*)bundleID completionBlock:(ZincCompletionBlock)completion;
- (ZincTaskRef*) updateBundleWithID:(NSString*)bundleID;

/**
 @discussion Update all bundles
 */
- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion;


#pragma mark -
#pragma mark Loading Bundles

/**
 @discussion Main, offical way to get a bundle of files. Will raise an exception if the repo is not initialized
 */
- (ZincBundle*) bundleWithID:(NSString*)bundleID;

- (ZincBundleState) stateForBundleWithID:(NSString*)bundleID;


#pragma mark -
#pragma mark Download Policy

/**
 */
@property (nonatomic, strong, readonly) ZincDownloadPolicy* downloadPolicy;

- (BOOL) doesPolicyAllowDownloadForBundleID:(NSString*)bundleID;



#pragma mark -
#pragma mark Tasks

@property (readonly) NSArray* tasks;

- (void) suspendAllTasks;
- (void) suspendAllTasksAndWaitExecutingTasksToComplete;
- (void) resumeAllTasks;
- (BOOL) isSuspended;
       
@end


#pragma mark -

@protocol ZincRepoDelegate <NSObject>

- (void) zincRepo:(ZincRepo*)repo didReceiveEvent:(ZincEvent*)event;

@end
