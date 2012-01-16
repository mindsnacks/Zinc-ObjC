//
//  ZCBundle.h
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"


@interface ZincBundle : NSObject

- (id) initWithBundleId:(NSString*)bundleId version:(ZincVersion)version bundleURL:(NSURL*)bundleURL;
@property (nonatomic, retain, readonly) NSString* bundleId;
@property (nonatomic, assign, readonly) ZincVersion version;

#pragma mark NSBundle-like access

- (NSURL *)URLForResource:(NSString *)name withExtension:(NSString *)ext;
- (NSURL *)URLForResource:(NSString *)name;

- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext;
- (NSString *)pathForResource:(NSString *)name;

/* DON'T retain this */
- (NSBundle*) nsbundle;

#pragma mark Utility

+ (NSString*) catalogIdFromBundleId:(NSString*)bundleId;
+ (NSString*) bundleNameFromBundleId:(NSString*)bundleId;

@end
