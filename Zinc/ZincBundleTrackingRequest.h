//
//  ZincBundleTrackingRequest.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZincBundleTrackingRequest : NSObject

/**
 * @discussion Bundle ID to track.
 */
@property (nonatomic, copy) NSString* bundleID;

/**
 * @discussion Distribution name to track.
 */
@property (nonatomic, copy) NSString* distribution;

/**
 * @discussion Bundle flavor name to track.
 */
@property (nonatomic, copy) NSString* flavor;

/**
 * @discussion Enable or disable automatic updates.
 */
@property (nonatomic, assign) BOOL updateAutomatically;

/**
 * @discussion Convenience constructor that includes all options.
 */
+ (ZincBundleTrackingRequest*) bundleTrackingRequestWithBundleID:(NSString*)bundleID
                                                    distribution:(NSString*)distribution
                                                          flavor:(NSString*)flavor
                                             automaticallyUpdate:(BOOL)automaticallyUpdate;

/**
 * @discussion Convenience constructor for tracking requests with no flavor.
 */
+ (ZincBundleTrackingRequest*) bundleTrackingRequestWithBundleID:(NSString*)bundleID
                                                    distribution:(NSString*)distribution
                                             automaticallyUpdate:(BOOL)automaticallyUpdate;

@end
