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

extern ZincBundleState ZincBundleStateFromName(NSString* name);

/**
 Adds the "com.apple.MobileBackup" attribute to prevent iCloud backup
 @param path The file path
 */
extern int ZincAddSkipBackupAttributeToFileWithPath(NSString * path);

/**
 Adds the "com.apple.MobileBackup" attribute to prevent iCloud backup
 @url path The file URL
 */
extern int ZincAddSkipBackupAttributeToFileWithURL(NSURL* url);

/**
 Returns the application documents directory by searching for `NSDocumentDirectory`
 */
extern NSString* ZincGetApplicationDocumentsDirectory(void);

/**
 Returns the cache directory by searching for `NSCachesDirectory`
 */
extern NSString* ZincGetApplicationCacheDirectory(void);

/**
 Creates a new, unique temporary directory
 */
extern NSString* ZincGetUniqueTemporaryDirectory(void);

/**
 Parse the catalog ID from a bundle ID

 @param bundleID The bunlde ID
 */
extern NSString* ZincCatalogIDFromBundleID(NSString* bundleID);

/**
 Parse the bundle namefrom a bundle ID
 
 @param bundleID The bunlde ID
 */
extern NSString* ZincBundleNameFromBundleID(NSString* bundleID);

/**
 Create a bundle ID from catalog ID and bundle name

 @param catalogID The catalog ID
 @param bundleName The bundle name
 */
extern NSString* ZincBundleIDFromCatalogIDAndBundleName(NSString* catalogID, NSString* bundleName);

/**
 Parse the bundle ID from a bundle descriptor.

 @param bundleDescriptor A bundle descriptor in the format <bundleid>-<version>
 */
extern NSString* ZincBundleIDFromBundleDescriptor(NSString* bundleDescriptor);

/**
 Parse the bundle version from a bundle descriptor.

 @param bundleDescriptor A bundle descriptor in the format <bundleid>-<version>
 */
extern ZincVersion ZincBundleVersionFromBundleDescriptor(NSString* bundleDescriptor);
