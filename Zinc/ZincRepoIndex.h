//
//  ZincRepoIndex.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"


typedef enum {
    ZincBundleStateNone      = 0,
    ZincBundleStateCloning   = 1,
    ZincBundleStateAvailable = 2,
    ZincBundleStateDeleting  = 3,
} ZincBundleState;

@interface ZincRepoIndex : NSObject

- (id) init;

- (void) addSourceURL:(NSURL*)url;
- (void) removeSourceURL:(NSURL*)url;
- (NSSet*) sourceURLs;

- (void) addTrackedBundleId:(NSString*)bundleId distribution:(NSString*)distro;
- (void) removeTrackedBundleId:(NSString*)bundleId;
- (NSSet*) trackedBundleIds;
- (NSString*) trackedDistributionForBundleId:(NSString*)bundleId;

- (void) setState:(ZincBundleState)state forBundle:(NSURL*)bundleResource;
- (ZincBundleState) stateForBundle:(NSURL*)bundleResource;
- (void) removeBundle:(NSURL*)bundleResource;

- (NSSet*) cloningBundles;
- (NSSet*) availableBundles;

#pragma mark Encoding

+ (id) repoIndexFromDictionary:(NSDictionary*)dict error:(NSError**)outError;
- (NSDictionary*) dictionaryRepresentation;
- (NSString*) jsonRepresentation:(NSError**)outError;

@end
