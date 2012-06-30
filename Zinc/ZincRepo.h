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

@protocol ZincRepoDelegate;
@class ZincManifest;
@class ZincBundle;
@class ZincEvent;

@interface ZincRepo : NSObject

// !!!: Note all repos start suspended. After obtaining a repo object,
// you must all [repo resumeAllTasks]

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL error:(NSError**)outError;
+ (ZincRepo*) repoWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue error:(NSError**)outError;

+ (BOOL) repoExistsAtURL:(NSURL*)fileURL;

@property (nonatomic, assign) id<ZincRepoDelegate> delegate;
@property (nonatomic, retain, readonly) NSURL* url;

@property (nonatomic, assign) NSTimeInterval refreshInterval;

#pragma mark Sources

- (void) addSourceURL:(NSURL*)url;
- (void) removeSourceURL:(NSURL*)url;

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion;

#pragma mark Bundles

- (void) beginTrackingBundleWithId:(NSString*)bundleId distribution:(NSString*)distro;
- (void) beginTrackingBundleWithId:(NSString *)bundleId distribution:(NSString *)distro automaticallyBootstrapFromPath:(NSString*)dir;
//- (void) beginTrackingBundleWithId:(NSString *)bundleId distribution:(NSString *)distro bootstrap
- (void) stopTrackingBundleWithId:(NSString*)bundleId;

- (NSSet*) trackedBundleIds;

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion;

- (ZincBundleState) stateForBundleWithId:(NSString*)bundleId;

- (ZincBundle*) bundleWithId:(NSString*)bundleId;

#pragma mark Tasks

@property (readonly) NSArray* tasks;

- (void) suspendAllTasks;
- (void) resumeAllTasks;
- (BOOL) isSuspended;
       
@end


@protocol ZincRepoDelegate <NSObject>

- (void) zincRepo:(ZincRepo*)repo didReceiveEvent:(ZincEvent*)event;

@end
