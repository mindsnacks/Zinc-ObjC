//
//  ZincOperationQueueGroup.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperationQueueGroup.h"

@interface ZincOperationQueueGroup ()
@property (nonatomic, retain) NSMutableDictionary* queuesByClass;
@property (atomic) BOOL mySuspended;
@end

@implementation ZincOperationQueueGroup

@synthesize queuesByClass = _queuesByClass;
@synthesize mySuspended = _mySuspended;

- (id)init
{
    self = [super init];
    if (self) {
        self.queuesByClass = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    self.queuesByClass = nil;
    [super dealloc];
}

- (NSOperationQueue*) getQueueForClass:(Class)theClass
{
    @synchronized(self) {
        NSString* className = NSStringFromClass(theClass);
        NSOperationQueue* queue = [self.queuesByClass objectForKey:className];
        if (queue == nil) {
            queue = [[[NSOperationQueue alloc] init] autorelease];
            [queue setSuspended:self.mySuspended];
            [self.queuesByClass setObject:queue forKey:className];
        }
        return queue;
    }
}

- (void) addOperation:(NSOperation*)operation
{
    NSOperationQueue* queue = [self getQueueForClass:[operation class]];
    [queue addOperation:operation];
}

- (void) setMaxConcurrentOperationCount:(NSInteger)cnt forClass:(Class)theClass
{
    NSOperationQueue* queue = [self getQueueForClass:theClass];
    queue.maxConcurrentOperationCount = cnt;
}

- (void)setSuspended:(BOOL)b
{
    @synchronized(self) {
        self.mySuspended = b;
        NSArray* allQueues = [self.queuesByClass allValues];
        for (NSOperationQueue* queue in allQueues) {
            [queue setSuspended:b];
        }
    }
}

- (BOOL)isSuspended
{
    return self.mySuspended;
}



@end
