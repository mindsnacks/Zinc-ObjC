//
//  ZincArchiveExtractTask.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

//#import "ZincTask.h"

@class ZincRepo;

@interface ZincArchiveExtractOperation : NSOperation

- (id) initWithZincRepo:(ZincRepo*)repo archivePath:(NSString*)archivePath;                

@property (nonatomic, assign, readonly) ZincRepo* repo;
@property (nonatomic, retain, readonly) NSString* archivePath;

@property (nonatomic, retain, readonly) NSError* error;

@end
