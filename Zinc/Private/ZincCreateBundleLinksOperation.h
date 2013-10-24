//
//  ZincCreateBundleLinksOperation.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/14/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincOperation.h"

@class ZincRepo;
@class ZincManifest;


@interface ZincCreateBundleLinksOperation : ZincOperation

- (id) initWithRepo:(ZincRepo*)repo manifest:(ZincManifest*)manifest;

@property (nonatomic, weak, readonly) ZincRepo* repo;
@property (nonatomic, strong, readonly) ZincManifest* manifest;

#pragma mark -

@property (nonatomic, strong, readonly) NSError* error;

- (BOOL) isSuccessful;

@end
