//
//  ZincSerialQueueProxy.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/23/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZincSerialQueueProxy : NSProxy

- (id)initWithTarget:(id)target;

@property (retain, readonly) id target;

- (void) executeBlock:(dispatch_block_t)block;

@end
