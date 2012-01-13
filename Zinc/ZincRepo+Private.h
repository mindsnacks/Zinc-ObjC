//
//  Zincself.repo+Private.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepo.h"

@class ZincRepoIndex;
@class ZincCatalog;
@class ZincSource;
@class ZincTask;
@class ZincManifest;

@interface ZincRepo ()

- (id) initWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)operationQueue;

- (NSURL*) indexURL;
@property (nonatomic, retain) ZincRepoIndex* index;

- (void) registerSource:(NSURL*)source forCatalog:(ZincCatalog*)catalog;
- (NSArray*) sourcesForCatalogId:(NSString*)catalogId;
- (NSString*) pathForCatalogIndex:(ZincCatalog*)catalog;

- (void) addManifest:(ZincManifest*)manifest forBundleId:(NSString*)bundleId;
- (BOOL) removeManifestForBundleId:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError;
- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
- (ZincManifest*) manifestWithBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError;
- (NSString*) pathForManifestWithBundleId:(NSString*)identifier version:(ZincVersion)version;

#pragma mark Bundles

- (void) registerBundle:(NSURL*)bundleResource;
- (void) deregisterBundle:(NSURL*)bundleResource;

- (NSString*) pathForBundleWithId:(NSString*)bundleId version:(ZincVersion)version;

// includes all currently tracked and open bundles
// returns NSURLs (ZincBundleDescriptors)
- (NSSet*) activeBundles;

#pragma mark Files

- (NSString*) pathForFileWithSHA:(NSString*)sha;

- (ZincTask*) getOrAddTask:(ZincTask*)task;
- (void) addOperation:(NSOperation*)operation;

#pragma mark Paths

- (NSString*) filesPath;
- (NSString*) bundlesPath;
- (NSString*) downloadsPath;

@end

