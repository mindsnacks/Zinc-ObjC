//
//  ZincArchiveExtractTask.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

@class ZincRepo;

@interface ZincArchiveExtractOperation : NSOperation

- (id) initWithZincRepo:(ZincRepo*)repo archivePath:(NSString*)archivePath;                

@property (nonatomic, weak, readonly) ZincRepo* repo;
@property (nonatomic, copy, readonly) NSString* archivePath;

@property (nonatomic, copy, readonly) NSError* error;

@end
