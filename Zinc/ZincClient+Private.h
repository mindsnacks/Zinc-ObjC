//
//  ZincClient+Private.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincClient.h"

@class AFHTTPRequestOperation;
@class ZincOperation;
@class ZincCatalog;
@class ZincSource;
//@class ZincTask;
@class ZincTask2;

@interface ZincClient ()

//- (AFHTTPRequestOperation*) queuedHTTPRequestOperationForRequest:(NSURLRequest*)request;

//- (ZincOperation*) queuedAtomicFileWriteOperationForData:(NSData*)data path:(NSString*)path;

- (NSString*) pathForCatalogIndex:(ZincCatalog*)catalog;

- (void) registerSource:(ZincSource*)source forCatalog:(ZincCatalog*)catalog;

- (void) addOperation:(NSOperation*)operation;

- (ZincTask2*) taskForKey:(NSString*)key;

- (NSArray*) sourcesForCatalogIdentifier:(NSString*)catalogId;

- (NSString*) pathForManifestWithBundleIdentifier:(NSString*)identifier version:(ZincVersion)version;

- (void) registerManifest:(ZincManifest*)manifest forBundleId:(NSString*)bundleId;

- (ZincTask2*) getOrAddTask:(ZincTask2*)task;

- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;

- (ZincManifest*) manifestWithBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError;

- (NSString*) pathForBundleWithId:(NSString*)bundleId version:(ZincVersion)version;


@end

