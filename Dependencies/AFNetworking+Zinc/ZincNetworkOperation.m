//
//  ZincNetworkOperation.m
//  
//
//  Created by Andy Mroczkowski on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZincNetworkOperation.h"

typedef enum {
    ZincNetworkOperationReadyState       = 1,
    ZincNetworkOperationExecutingState   = 2,
    ZincNetworkOperationFinishedState    = 3,
} ZincNetworkOperationState;

NSString * const ZincNetworkErrorDomain = @"com.mindsnacks.zinc.network.error";

NSString * const ZincNetworkOperationDidStartNotification = @"ZincNetworkOperationDidStartNotification";
NSString * const ZincNetworkOperationDidFinishNotification = @"ZincNetworkOperationDidFinishNotification";

static inline NSString * ZincKeyPathFromOperationState(ZincNetworkOperationState state) {
    switch (state) {
        case ZincNetworkOperationReadyState:
            return @"isReady";
        case ZincNetworkOperationExecutingState:
            return @"isExecuting";
        case ZincNetworkOperationFinishedState:
            return @"isFinished";
        default:
            return @"state";
    }
}

@interface ZincNetworkOperation ()
@property (readwrite, nonatomic, assign) ZincNetworkOperationState state;
@property (readwrite, nonatomic, assign, getter = isCancelled) BOOL cancelled;

- (BOOL)shouldTransitionToState:(ZincNetworkOperationState)state;
@end

@implementation ZincNetworkOperation

@synthesize runLoopModes = _runLoopModes;
@synthesize state = _state;
@synthesize cancelled = _cancelled;
@synthesize error = _error;

+ (void)networkRequestThreadEntryPoint:(id)__unused object 
{
    do {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [[NSRunLoop currentRunLoop] run];
        [pool drain];
    } while (YES);
}

+ (NSThread *)networkRequestThread
{
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}

- (id)init
{
    self = [super init];
    if (!self) {
		return nil;
    }
    
    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
    
    self.state = ZincNetworkOperationReadyState;

    return self;
}

- (void)dealloc
{
    [_runLoopModes release];
    [_error release];
    [super dealloc];
}

- (void)setCompletionBlock:(void (^)(void))block {
    if (!block) {
        [super setCompletionBlock:nil];
    } else {
        __block id _blockSelf = self;
        [super setCompletionBlock:^ {
            block();
            [_blockSelf setCompletionBlock:nil];
        }];
    }
}

- (BOOL)isReady 
{
    return self.state == ZincNetworkOperationReadyState;
}

- (void)setState:(ZincNetworkOperationState)state {
    if (![self shouldTransitionToState:state]) {
        return;
    }
    
    NSString *oldStateKey = ZincKeyPathFromOperationState(self.state);
    NSString *newStateKey = ZincKeyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
    
    switch (state) {
        case ZincNetworkOperationExecutingState:
            [[NSNotificationCenter defaultCenter] postNotificationName:ZincNetworkOperationDidStartNotification object:self];
            break;
        case ZincNetworkOperationFinishedState:
            [[NSNotificationCenter defaultCenter] postNotificationName:ZincNetworkOperationDidFinishNotification object:self];
            break;
        default:
            break;
    }
}

- (BOOL)shouldTransitionToState:(ZincNetworkOperationState)state {    
    switch (self.state) {
        case ZincNetworkOperationReadyState:
            switch (state) {
                case ZincNetworkOperationExecutingState:
                    return YES;
                default:
                    return NO;
            }
        case ZincNetworkOperationExecutingState:
            switch (state) {
                case ZincNetworkOperationFinishedState:
                    return YES;
                default:
                    return NO;
            }
        case ZincNetworkOperationFinishedState:
            return NO;
        default:
            return YES;
    }
}

- (void)setCancelled:(BOOL)cancelled {
    [self willChangeValueForKey:@"isCancelled"];
    _cancelled = cancelled;
    [self didChangeValueForKey:@"isCancelled"];
    
    if ([self isCancelled]) {
        self.state = ZincNetworkOperationFinishedState;
    }
}

#pragma mark - NSOperation

- (void)start 
{
    if (![self isReady]) {
        return;
    }
    
    self.state = ZincNetworkOperationExecutingState;
    
    [self performSelector:@selector(main) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:YES modes:[self.runLoopModes allObjects]];
}

- (BOOL)isFinished
{
    return self.state == ZincNetworkOperationFinishedState;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return self.state == ZincNetworkOperationExecutingState;
}

- (void)finish
{
    self.state = ZincNetworkOperationFinishedState;
}

- (void)cancel
{
    if ([self isFinished]) {
        return;
    }
    
    [super cancel];
    
    self.cancelled = YES;
}

@end
