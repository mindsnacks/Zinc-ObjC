//
//  ZCBundle.h
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Zinc.h"
#import "ZCManifest.h"

@class ZincClient;

enum {
    ZCBundleStateAvailable = 0x1,
    ZCBundleStateUpdating = 0x1>>1,
};

typedef NSInteger ZCBundleState;


@interface ZCBundle : NSObject

- (NSArray*) availableVersions;
//- (NSURL*) url;

//@property (nonatomic, assign) ZincVersion version;

// TODO: make private?
@property (nonatomic, retain) ZCManifest* manifest;

//- (NSURL*) urlForResource:(NSURL*)url;
//- (NSString*) pathForResource:(NSString*)path;

// TODO: rename
@property (nonatomic, assign) ZincClient* manager;

@end
