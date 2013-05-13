//
//  ZincResourceDescriptor.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"

@interface NSURL (ZincResource)

+ (NSURL*) zincResourceForCatalogWithId:(NSString*)catalogID;
- (BOOL) isZincCatalogResource;
- (NSString*) zincCatalogID;

+ (NSURL*) zincResourceForManifestWithId:(NSString*)bundleID version:(ZincVersion)verion;
- (BOOL) isZincManifestResource;

+ (NSURL*) zincResourceForBundleWithID:(NSString*)bundleID version:(ZincVersion)version;
+ (NSURL*) zincResourceForBundleDescriptor:(NSString*)bundleDescriptor;
- (BOOL) isZincBundleResource;

+ (NSURL*) zincResourceForArchiveWithId:(NSString*)bundleID version:(ZincVersion)version;
- (BOOL) isZincArchiveResource;

- (NSString*) zincBundleID;
- (ZincVersion) zincBundleVersion;

+ (NSURL*) zincResourceForObjectWithSHA:(NSString*)sha inCatalogID:(NSString*)catalogID;
- (BOOL) isZincObjectResource;
- (NSString*) zincObjectSHA;

@end
