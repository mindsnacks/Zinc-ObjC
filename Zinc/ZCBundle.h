//
//  ZCBundle.h
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Zinc.h"

@interface ZCBundle : NSObject

- (NSArray*) availableVersions;
- (NSURL*) url;

@property (nonatomic, assign) NSUInteger* version;

+ (ZCBundle*) bundleWithURL:(NSURL*)url error:(NSError**)outError;
+ (ZCBundle*) bundleWithURL:(NSURL*)url version:(ZincVersionMajor)version error:(NSError**)outError;

+ (ZCBundle*) bundleWithPath:(NSString*)path error:(NSError**)outError;;
+ (ZCBundle*) bundleWithPath:(NSString*)path version:(ZincVersionMajor)version error:(NSError**)outError;;

@end
