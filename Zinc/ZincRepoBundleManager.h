//
//  ZincRepoBundleManager.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 5/14/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"

@class ZincRepo;
@class ZincBundle;

@interface ZincRepoBundleManager : NSObject

- (id) initWithZincRepo:(ZincRepo*)zincRepo;

@property (nonatomic, assign) ZincRepo* repo;

#pragma mark Internal

- (ZincBundle*) bundleWithID:(NSString*)bundleID version:(ZincVersion)version;

- (NSSet*) activeBundles;

- (void) bundleWillDeallocate:(ZincBundle*)bundle;

@end
