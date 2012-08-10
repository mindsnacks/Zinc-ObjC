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
 * @discussion Distribution name to track. Ignored for bootstrapping.
 */
@property (nonatomic, copy) NSString* distribution;

/**
 * @discussion Bundle flavor name to track.
 */
@property (nonatomic, copy) NSString* flavor;

/**
 * @discussion Enable or disable automatic updates. Ignored for bootstrapping.
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

/**
 * @discussion Convenience constructor for bootstrap operations with flavor.
 * Distribution and automatic updates are ignored for bootstrap operations, so
 * they are omitted.
 */
+ (ZincBundleTrackingRequest*) bundleTrackingRequestWithBundleID:(NSString*)bundleID
                                                          flavor:(NSString*)flavor;

/**
 * @discussion Convenience constructor for bootstrap operation.
 * Distribution and automatic updates are ignored for bootstrap operations, so
 * they are omitted.
 */
+ (ZincBundleTrackingRequest*) bundleTrackingRequestWithBundleID:(NSString*)bundleID;



@end
