//
//  ZincAtomicFileWriteOperation.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZincAtomicFileWriteOperation : NSOperation

- (id)initWithData:(NSData*)data path:(NSString*)path;

@property (nonatomic, retain) NSData* data;
@property (nonatomic, retain) NSString* path;

@property (readonly, retain) NSError* error;

@end
