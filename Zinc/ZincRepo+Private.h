//
//  Zincself.repo+Private.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepo.h"

@class ZincCatalog;
@class ZincSource;
@class ZincTask;
@class ZincManifest;

@interface ZincRepo ()

- (id) initWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)operationQueue;

- (NSArray*) sourcesForCatalogIdentifier:(NSString*)catalogId;
- (NSString*) pathForCatalogIndex:(ZincCatalog*)catalog;
- (void) registerSource:(ZincSource*)source forCatalog:(ZincCatalog*)catalog;

- (void) registerManifest:(ZincManifest*)manifest forBundleId:(NSString*)bundleId;
- (BOOL) removeManifestForBundleId:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError;
- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
- (ZincManifest*) manifestWithBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError;
- (NSString*) pathForManifestWithBundleId:(NSString*)identifier version:(ZincVersion)version;

#pragma mark Bundles

- (NSString*) pathForBundleWithId:(NSString*)bundleId version:(ZincVersion)version;

// includes all currently tracked and open bundles
// returns ZincBundleDescriptors
- (NSArray*) activeBundles;

#pragma mark Files

- (NSString*) pathForFileWithSHA:(NSString*)sha;

- (ZincTask*) getOrAddTask:(ZincTask*)task;
- (void) addOperation:(NSOperation*)operation;

#pragma mark Paths

- (NSString*) filesPath;
- (NSString*) bundlesPath;
- (NSString*) downloadsPath;

@end

