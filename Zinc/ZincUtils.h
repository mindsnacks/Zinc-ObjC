//
//  ZincUtils.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/15/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark Utility Functions

extern void ZincAddSkipBackupAttributeToFile(NSURL* url);
extern NSString* ZincGetApplicationDocumentsDirectory(void);
extern NSString* ZincGetApplicationCacheDirectory(void);
extern NSString* ZincGetUniqueTemporaryDirectory(void);

extern NSString* ZincCatalogIdFromBundleId(NSString* bundleId);
extern NSString* ZincBundleNameFromBundleId(NSString* bundleId);

