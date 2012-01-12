//
//  ZCBundle.h
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Zinc.h"

//@class ZincRepo;

//enum {
//    ZCBundleStateAvailable = 0x1,
//    ZCBundleStateUpdating = 0x1>>1,
//};
//
//typedef NSInteger ZCBundleState;


@interface ZincBundle : NSObject

- (id) initWithBundleId:(NSString*)bundleId version:(ZincVersion)version;
@property (nonatomic, retain, readonly) NSString* bundleId;
@property (nonatomic, assign, readonly) ZincVersion version;

- (NSString*) descriptor;

#pragma mark Utility

+ (NSString*) catalogIdFromBundleId:(NSString*)bundleId;
+ (NSString*) bundleNameFromBundleId:(NSString*)bundleId;

@end
