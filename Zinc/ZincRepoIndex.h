//
//  ZincRepoIndex.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"
#import "ZincRepo.h"

@class ZincTrackingInfo;

@interface ZincRepoIndex : NSObject

- (id) init;

- (void) addSourceURL:(NSURL*)url;
- (void) removeSourceURL:(NSURL*)url;
- (NSSet*) sourceURLs;

- (void) setTrackingInfo:(ZincTrackingInfo*)ref forBundleId:(NSString*)bundleId;
- (void) removeTrackedBundleId:(NSString*)bundleId;
- (NSSet*) trackedBundleIds;
- (NSString*) trackedDistributionForBundleId:(NSString*)bundleId;
- (NSString*) trackedFlavorForBundleId:(NSString*)bundleId;
- (ZincTrackingInfo*) trackingInfoForBundleId:(NSString*)bundleId;
- (void) setState:(ZincBundleState)state forBundle:(NSURL*)bundleResource;
- (ZincBundleState) stateForBundle:(NSURL*)bundleResource;
- (void) removeBundle:(NSURL*)bundleResource;

- (NSSet*) cloningBundles;
- (NSSet*) availableBundles;

/*
 * Returns a _sorted_ array of available bundle versions
 */
- (NSArray*) availableVersionsForBundleId:(NSString*)bundleId;

- (ZincVersion) newestAvailableVersionForBundleId:(NSString*)bundleId;

#pragma mark External Bundles
/* 
 !!!: External bundles are not persisted by design, they should be re-registered each launch.
 */

- (void) registerExternalBundle:(NSURL*)bundleRes rootPath:(NSString*)rootPath;
- (NSString*) externalPathForBundle:(NSURL*)bundleRes;

- (NSArray*) registeredExternalBundles;

#pragma mark Encoding

+ (id) repoIndexFromDictionary:(NSDictionary*)dict error:(NSError**)outError;
- (NSDictionary*) dictionaryRepresentation;
- (NSData*) jsonRepresentation:(NSError**)outError;

@end
