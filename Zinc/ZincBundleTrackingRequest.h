//
//  ZincBundleTrackingRequest.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 `ZincBundleTrackingRequest`

 This class is part of the *Zinc Public API*.
 */
@interface ZincBundleTrackingRequest : NSObject

/**
Bundle ID to track.
 */
@property (nonatomic, copy) NSString* bundleID;

/**
 Distribution name to track.
 */
@property (nonatomic, copy) NSString* distribution;

/**
 Bundle flavor name to track.
 */
@property (nonatomic, copy) NSString* flavor;

/**
 Convenience constructor that includes all options.

 @param bundleID The bundle ID
 @param distribution The distribution name to track.
 @param flavor The bundle flavor.
 */
+ (instancetype) bundleTrackingRequestWithBundleID:(NSString*)bundleID
                                                    distribution:(NSString*)distribution
                                                          flavor:(NSString*)flavor;

/**
 Convenience constructor for tracking requests with no flavor.
 
 @param bundleID The bundle ID
 @param distribution The distribution name to track.
 */
+ (instancetype) bundleTrackingRequestWithBundleID:(NSString*)bundleID
                                                    distribution:(NSString*)distribution;

@end
