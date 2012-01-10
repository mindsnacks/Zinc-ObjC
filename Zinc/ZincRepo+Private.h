//
//  Zincself.repo+Private.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepo.h"

@class AFHTTPRequestOperation;
@class ZincOperation;
@class ZincCatalog;
@class ZincSource;
@class ZincTask;

@interface ZincRepo ()

- (NSArray*) sourcesForCatalogIdentifier:(NSString*)catalogId;
- (NSString*) pathForCatalogIndex:(ZincCatalog*)catalog;
- (void) registerSource:(ZincSource*)source forCatalog:(ZincCatalog*)catalog;

- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
- (ZincManifest*) manifestWithBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError;
- (NSString*) pathForManifestWithBundleIdentifier:(NSString*)identifier version:(ZincVersion)version;
- (void) registerManifest:(ZincManifest*)manifest forBundleId:(NSString*)bundleId;

- (NSString*) pathForBundleWithId:(NSString*)bundleId version:(ZincVersion)version;

- (ZincTask*) taskForKey:(NSString*)key;
- (ZincTask*) getOrAddTask:(ZincTask*)task;
- (void) addOperation:(NSOperation*)operation;

@end

