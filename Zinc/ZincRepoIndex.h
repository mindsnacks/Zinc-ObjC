//
//  ZincRepoIndex.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Zinc.h"

@class ZincBundleDescriptor;

@interface ZincRepoIndex : NSObject

- (id) init;

- (void) addSourceURL:(NSURL*)url;
- (void) removeSourceURL:(NSURL*)url;
- (NSSet*) sourceURLS;

- (void) addTrackedBundleId:(NSString*)bundleId distribution:(NSString*)distro;
- (void) removeTrackedBundleId:(NSString*)bundleId;
- (NSSet*) trackedBundleIds;
- (NSString*) trackedDistributionForBundleId:(NSString*)bundleId;

- (void) addAvailableBundle:(ZincBundleDescriptor*)bundleDesc;
- (void) removeAvailableBundle:(ZincBundleDescriptor*)bundleDesc;
- (NSSet*) availableBundles;

#pragma mark Encoding
- (id) initWithDictionary:(NSDictionary*)dict;
- (NSDictionary*) dictionaryRepresentation;
- (NSString*) jsonRepresentation:(NSError**)outError;

@end
