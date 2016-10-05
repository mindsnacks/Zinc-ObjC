//
//  Zinc.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/15/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double ZincVersionNumber;
FOUNDATION_EXPORT const unsigned char ZincVersionString[];

#import <Zinc/ZincGlobals.h>
#import <Zinc/ZincErrors.h>
#import <Zinc/ZincRepo.h>
#import <Zinc/ZincAgent.h>
#import <Zinc/ZincBundle.h>
#import <Zinc/ZincEvent.h>
#import <Zinc/ZincResource.h>
#import <Zinc/ZincBundleTrackingRequest.h>
#import <Zinc/ZincDownloadPolicy.h>
#import <Zinc/ZincProgress.h>
#import <Zinc/ZincActivity.h>
#import <Zinc/ZincOperation.h>
#import <Zinc/ZincTask.h>
#import <Zinc/ZincTaskRef.h>
#import <Zinc/ZincUtils.h>
#import <Zinc/ZincActivityMonitor.h>
#import <Zinc/ZincTaskMonitor.h>
#import <Zinc/ZincRepoMonitor.h>
#import <Zinc/ZincBundleAvailabilityMonitor.h>
#import <Zinc/NSData+Zinc.h>
#import <Zinc/NSError+Zinc.h>
#import <Zinc/NSFileManager+Zinc.h>
#import <Zinc/NSFileManager+ZincTar.h>
#import <Zinc/NSOperation+Zinc.h>
#import <Zinc/NSString+Zinc.h>
#import <Zinc/ZincDeepCopying.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    #import <Zinc/UIImage+Zinc.h>
    #import <Zinc/ZincAdminViewController.h>
#endif

