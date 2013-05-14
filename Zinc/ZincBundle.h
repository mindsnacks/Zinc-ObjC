//
//  ZCBundle.h
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"

@class ZincRepo;

@protocol ZincBundle

- (NSURL *)URLForResource:(NSString *)name;
- (NSString *)pathForResource:(NSString *)name;

@end


@interface NSBundle (ZincBundle) <ZincBundle>

- (NSURL *)URLForResource:(NSString *)name;
- (NSString *)pathForResource:(NSString *)name;

@end


@interface ZincBundle : NSProxy <ZincBundle>

@property (nonatomic, strong, readonly) ZincRepo* repo;
@property (nonatomic, strong, readonly) NSString* bundleID;
@property (nonatomic, assign, readonly) ZincVersion version;

- (NSURL*) resource;

- (NSBundle*) NSBundle;

#pragma mark Utility

// Deprecated, use functions in ZincUtils
+ (NSString*) catalogIDFromBundleID:(NSString*)bundleID;
+ (NSString*) bundleNameFromBundleID:(NSString*)bundleID;

@end


