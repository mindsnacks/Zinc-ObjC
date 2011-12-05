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
@property (nonatomic, retain, readonly) NSURL* url;

@property (nonatomic, assign) NSUInteger* version;

+ (ZCBundle*) bundleWithURL:(NSURL*)url error:(NSError**)outError;
+ (ZCBundle*) bundleWithPath:(NSString*)path error:(NSError**)outError;;

@end
