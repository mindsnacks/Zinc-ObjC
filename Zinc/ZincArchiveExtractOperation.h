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
@property (nonatomic, strong, readonly) NSString* archivePath;

@property (nonatomic, strong, readonly) NSError* error;

@end
