//
//  ZincSerialQueueProxy.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/23/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincSerialQueueProxy.h"

@interface ZincSerialQueueProxy ()
@property (retain, readwrite) id target;
@property (assign, readwrite) dispatch_queue_t queue;
@end


@implementation ZincSerialQueueProxy

@synthesize target = _target;
@synthesize queue = _queue;

- (id)initWithTarget:(id)target
{
    _target = [target retain];
    _queue = dispatch_queue_create("com.mindsnacks.zinc.serialqueueproxy", NULL);
    return self;
}

- (void)dealloc
{
    [_target release];
    dispatch_release(_queue);
    [super dealloc];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [(id)self.target methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation setTarget:self.target];

    if (dispatch_get_current_queue() == self.queue) {
        [anInvocation invoke];
    } else {
        __block typeof(self) blockself = self;
        dispatch_sync(blockself.queue, ^{
            [anInvocation invoke];
        });
    }
}

- (void) withTarget:(dispatch_block_t)block
{
    if (dispatch_get_current_queue() == self.queue) {
        block();   
    } else {
        dispatch_sync(self.queue, block);
    }
}

@end
