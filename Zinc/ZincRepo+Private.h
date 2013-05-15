//
//  Zincself.repo+Private.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepo.h"
#import "ZincRepoIndex.h"

#define kZincRepoDefaultObjectDownloadCount (5)
#define kZincRepoDefaultNetworkOperationCount (kZincRepoDefaultObjectDownloadCount*2)
#define kZincRepoDefaultAutoRefreshInterval (120)
#define kZincRepoDefaultCacheCount (20)

@class ZincRepoIndex;
@class ZincCatalog;
@class ZincTask;
@class ZincTaskDescriptor;
@class ZincManifest;
@class KSReachability;

@interface ZincRepo ()

- (id) initWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)operationQueue reachability:(KSReachability*)reachability;
@property (nonatomic, strong) ZincRepoIndex* index;
@property (nonatomic, strong) NSFileManager* fileManager;

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

- (ZincVersion) versionForBundleID:(NSString*)bundleID distribution:(NSString*)distro;

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

#pragma mark Tasks

/**
 
 @discussion Internal method to queue or get a task.
 
 @param taskDescriptor Descriptor describing the task to be queued. Will attempt to get an existing task if present
 @param input Abritrary data to pass to the task, akin to `userInfo`
 @param parent If not nil, the task will be added as a dependency to parent, i.e., `[parent addDependency:task]`
 @param dependencies Additional dependencies of the task. i.e., `[task addDependency:dep]`

 */
- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input parent:(NSOperation*)parent dependencies:(NSArray*)dependencies;

// Convenience methods - omitted parameters are nil

- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor;
- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input;
- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input dependencies:(NSArray*)dependencies;

- (void) addOperation:(NSOperation*)operation;

#pragma mark Paths

- (NSString*) filesPath;
- (NSString*) bundlesPath;
- (NSString*) downloadsPath;

#pragma mark Events

- (void) logEvent:(ZincEvent*)event;

@end

