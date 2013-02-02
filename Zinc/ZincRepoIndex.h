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

#define kZincRepoIndexCurrentFormat (2)

@class ZincTrackingInfo;
@class ZincExternalBundleInfo;

@interface ZincRepoIndex : NSObject

/**
 @discussion Inits with current format kZincRepoIndexCurrentFormat
 */
- (id) init;
- (id) initWithFormat:(NSInteger)format;

@property (nonatomic, assign) NSInteger format;
+ (NSSet*) validFormats;

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

#pragma mark External Bundles
/* 
 !!!: External bundles are not persisted by design, they should be re-registered each launch.
 */

- (void) registerExternalBundle:(NSURL*)bundleRes manifestPath:(NSString*)manifestPath bundleRootPath:(NSString*)rootPath;

- (ZincExternalBundleInfo*) infoForExternalBundle:(NSURL*)bundleRes;

- (NSArray*) registeredExternalBundles;

#pragma mark Encoding

+ (id) repoIndexFromDictionary:(NSDictionary*)dict error:(NSError**)outError;
- (NSDictionary*) dictionaryRepresentation;
- (NSData*) jsonRepresentation:(NSError**)outError;

@end
