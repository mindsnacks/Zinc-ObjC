//
//  ZincBundleVersionHelper.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 10/24/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"

@class ZincRepo;
@class ZincBundle;

@interface ZincBundleVersionHelper : NSObject

- (ZincVersion) versionForBundleID:(NSString*)bundleID distribution:(NSString*)distro versionSpecifier:(ZincBundleVersionSpecifier)versionSpec repo:(ZincRepo*)repo;

- (ZincVersion) versionForBundleID:(NSString *)bundleID versionSpecifier:(ZincBundleVersionSpecifier)versionSpec repo:(ZincRepo*)repo;

- (ZincVersion) versionForBundleID:(NSString *)bundleID repo:(ZincRepo*)repo;

- (ZincVersion) currentDistroVersionForBundleID:(NSString*)bundleID repo:(ZincRepo*)repo;

- (BOOL) bundleResource:(NSURL*)bundleResource satisfiesVersionSpecifier:(ZincBundleVersionSpecifier)versionSpec repo:(ZincRepo*)repo;

- (BOOL) hasSpecifiedVersion:(ZincBundleVersionSpecifier)versionSpec forBundleID:(NSString*)bundleID repo:(ZincRepo*)repo;

@end
