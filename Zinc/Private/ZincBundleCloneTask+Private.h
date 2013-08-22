//
//  ZincBundleCloneTask+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 6/19/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleCloneTask.h"

@class ZincManifest;

@interface ZincBundleCloneTask ()

@property (strong) NSFileManager* fileManager;

- (void) setUp;
- (void) completeWithSuccess:(BOOL)success;

- (NSString*) getTrackedFlavor;

- (BOOL) createBundleLinksForManifest:(ZincManifest*)manifest;

@end