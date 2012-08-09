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

@property (retain) NSFileManager* fileManager;

- (void) setUp;
- (void) complete;

- (NSString*) getTrackedFlavor;

- (BOOL) createBundleLinksForManifest:(ZincManifest*)manifest;

@end