//
//  ZincArchiveExtractTask.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperation.h"

@class ZincRepo;
@class ZincManifest;

@interface ZincArchiveExtractOperation : ZincOperation

- (id) initWithZincRepo:(ZincRepo*)repo archivePath:(NSString*)archivePath;                

/**
 @param manifest only used for progress calculation
 */
- (id) initWithZincRepo:(ZincRepo*)repo archivePath:(NSString*)archivePath manifest:(ZincManifest*)manifest;

@property (nonatomic, weak, readonly) ZincRepo* repo;
@property (nonatomic, copy, readonly) NSString* archivePath;
@property (nonatomic, strong, readonly) ZincManifest* manifest;

@property (nonatomic, copy, readonly) NSError* error;

@end
