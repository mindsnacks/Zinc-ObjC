//
//  ZCBundle.h
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZCBundle : NSObject

- (NSArray*) availableVersions;
@property (nonatomic, retain, readonly) NSURL* url;

@property (nonatomic, assign) NSUInteger* version;

- (id) initWithPath:(NSString*)path;
- (id) initWithURL:(NSURL*)url;


@end
