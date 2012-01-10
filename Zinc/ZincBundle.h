//
//  ZCBundle.h
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Zinc.h"
#import "ZincManifest.h"

@class ZincRepo;

enum {
    ZCBundleStateAvailable = 0x1,
    ZCBundleStateUpdating = 0x1>>1,
};

typedef NSInteger ZCBundleState;


@interface ZincBundle : NSObject

- (id) initWithBundleId:(NSString*)bundleId version:(ZincVersion)version repo:(ZincRepo*)repo;
@property (nonatomic, retain, readonly) ZincRepo* repo;
@property (nonatomic, retain, readonly) NSString* bundleId;
@property (nonatomic, assign, readonly) ZincVersion version;

// TODO: make private?
@property (nonatomic, retain) ZincManifest* manifest;

- (NSURL*) urlForResource:(NSString*)resource;
- (NSString*) pathForResource:(NSString*)path;

- (NSString*) descriptor;

#pragma mark Utility

+ (NSString*) sourceFromBundleIdentifier:(NSString*)bundleId;
+ (NSString*) nameFromBundleIdentifier:(NSString*)bundleId;
+ (NSString*) descriptorForBundleId:(NSString*)bundleId version:(ZincVersion)version;

@end
