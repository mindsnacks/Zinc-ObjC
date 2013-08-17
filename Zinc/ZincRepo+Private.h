//
//  Zincself.repo+Private.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepo.h"
#import "ZincRepoIndex.h"
#import "ZincRepoTaskManager.h"

#define kZincRepoDefaultObjectDownloadCount (5)
#define kZincRepoDefaultNetworkOperationCount (kZincRepoDefaultObjectDownloadCount*2)
#define kZincRepoDefaultCacheCount (20)

@class ZincRepoIndex;
@class ZincCatalog;
@class ZincManifest;

@interface ZincRepo ()

- (id) initWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)operationQueue;
@property (nonatomic, strong) ZincRepoIndex* index;
@property (nonatomic, strong) NSFileManager* fileManager;
@property (nonatomic, strong) ZincRepoTaskManager* taskManager;

- (NSURL*) indexURL;

- (void) completeInitialization;

- (void) registerSource:(NSURL*)source forCatalog:(ZincCatalog*)catalog;
- (NSArray*) sourcesForCatalogID:(NSString*)catalogID;

- (void) registerCatalog:(ZincCatalog*)catalog;
- (NSString*) pathForCatalogIndex:(ZincCatalog*)catalog;

- (void) addManifest:(ZincManifest*)manifest forBundleID:(NSString*)bundleID;
- (BOOL) removeManifestForBundleID:(NSString*)bundleID version:(ZincVersion)version error:(NSError**)outError;
- (BOOL) hasManifestForBundleIDentifier:(NSString*)bundleID version:(ZincVersion)version;
- (ZincManifest*) manifestWithBundleID:(NSString*)bundleID version:(ZincVersion)version error:(NSError**)outError;
- (NSString*) pathForManifestWithBundleID:(NSString*)identifier version:(ZincVersion)version;

#pragma mark Bundles

/*
 * TODO: document the difference between this and catalogVersionForBundleID
 */
- (ZincVersion) versionForBundleID:(NSString*)bundleID distribution:(NSString*)distro;

/*
 * TODO: document the difference between this and versionForBundleID
 */
- (ZincVersion) catalogVersionForBundleID:(NSString*)bundleID distribution:(NSString*)distro;

- (void) registerBundle:(NSURL*)bundleResource status:(ZincBundleState)status;
- (void) deregisterBundle:(NSURL*)bundleResource completion:(dispatch_block_t)completion;
- (void) deregisterBundle:(NSURL*)bundleResource;

- (NSString*) pathForBundleWithID:(NSString*)bundleID version:(ZincVersion)version;

// includes all currently tracked and open bundles
// returns NSURLs (ZincBundleDescriptors)
- (NSSet*) activeBundles;

#pragma mark Files

- (NSString*) pathForFileWithSHA:(NSString*)sha;
- (BOOL) hasFileWithSHA:(NSString*)sha;

// external files are registered via registerExternalBundleWithManifestPath:bundleRootPath:error:
// clone tasks can copy the file from a local path instead of downloading from the catalog
- (NSString*) externalPathForFileWithSHA:(NSString*)sha;


#pragma mark Paths

- (NSString*) filesPath;
- (NSString*) bundlesPath;
- (NSString*) downloadsPath;

#pragma mark Events

- (void) logEvent:(ZincEvent*)event;

- (void) postNotification:(NSString*)notificationName userInfo:(NSDictionary*)userInfo;


@end

