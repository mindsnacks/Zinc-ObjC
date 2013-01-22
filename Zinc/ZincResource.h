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

+ (NSURL*) zincResourceForCatalogWithId:(NSString*)catalogId;
- (BOOL) isZincCatalogResource;
- (NSString*) zincCatalogId;

+ (NSURL*) zincResourceForManifestWithId:(NSString*)bundleId version:(ZincVersion)verion;
- (BOOL) isZincManifestResource;

+ (NSURL*) zincResourceForBundleWithId:(NSString*)bundleId version:(ZincVersion)version;
+ (NSURL*) zincResourceForBundleDescriptor:(NSString*)bundleDescriptor;
- (BOOL) isZincBundleResource;

+ (NSURL*) zincResourceForArchiveWithId:(NSString*)bundleId version:(ZincVersion)version;
- (BOOL) isZincArchiveResource;

- (NSString*) zincBundleId;
- (ZincVersion) zincBundleVersion;

+ (NSURL*) zincResourceForObjectWithSHA:(NSString*)sha inCatalogId:(NSString*)catalogId;
- (BOOL) isZincObjectResource;
- (NSString*) zincObjectSHA;

@end
