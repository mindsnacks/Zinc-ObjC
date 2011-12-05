//
//  ZCBundle+Private.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZCBundle.h"

@interface ZCBundle ()

- (id) initWithPath:(NSString*)path;
- (id) initWithURL:(NSURL*)url;

@property (nonatomic, retain) NSFileManager* fileManager;

+ (ZincFormat) readZincFormatFromURL:(NSURL*)url error:(NSError**)outError;

@end