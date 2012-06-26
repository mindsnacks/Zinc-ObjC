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

@interface ZincBundle : NSProxy <ZincBundle>

@property (nonatomic, retain, readonly) ZincRepo* repo;
@property (nonatomic, retain, readonly) NSString* bundleId;
@property (nonatomic, assign, readonly) ZincVersion version;

- (NSURL*) resource;

- (NSBundle*) NSBundle;

#pragma mark Utility

// Deprecated, use functions in ZincUtils
+ (NSString*) catalogIdFromBundleId:(NSString*)bundleId;
+ (NSString*) bundleNameFromBundleId:(NSString*)bundleId;

@end


@interface NSBundle (ZincBundle) <ZincBundle>  

- (NSURL *)URLForResource:(NSString *)name;
- (NSString *)pathForResource:(NSString *)name;

@end