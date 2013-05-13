//
//  ZincUtils.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/15/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZincGlobals.h"

#pragma mark Utility Functions

extern int ZincAddSkipBackupAttributeToFileWithPath(NSString * path);
extern int ZincAddSkipBackupAttributeToFileWithURL(NSURL* url);
extern NSString* ZincGetApplicationDocumentsDirectory(void);
extern NSString* ZincGetApplicationCacheDirectory(void);
extern NSString* ZincGetUniqueTemporaryDirectory(void);

extern NSString* ZincCatalogIDFromBundleID(NSString* bundleID);
extern NSString* ZincBundleNameFromBundleID(NSString* bundleID);
extern NSString* ZincBundleIDFromCatalogIDAndBundleName(NSString* catalogID, NSString* bundleName);

/**
 * @discussion a bundle descriptor is <bundleid>-<version>, ie, com.mindsnacks.cats-2
 */
 
extern NSString* ZincBundleIDFromBundleDescriptor(NSString* bundleDescriptor);
extern ZincVersion ZincBundleVersionFromBundleDescriptor(NSString* bundleDescriptor);
