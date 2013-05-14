//
//  ZincOperationQueueGroup.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperationQueueGroup.h"
#import "NSOperation+Zinc.h"

@interface ZincOperationQueueGroup ()
@property (atomic, retain) NSMutableDictionary* infoByClassName;
@property (atomic) BOOL mySuspended;
@property (atomic, retain) NSOperationQueue* defaultQueue;
@end

@interface ZincOperationQueueGroupInfo : NSObject
@property (nonatomic, retain) NSString* className;
@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;
@property (nonatomic, assign) BOOL isBarrier;
@property (nonatomic, retain) NSOperationQueue* queue;
@end

@implementation ZincOperationQueueGroupInfo

+ (ZincOperationQueueGroupInfo*) infoForClassName:(NSString*)className maxConcurrentOperationCount:(NSInteger)count
{
    ZincOperationQueueGroupInfo* info = [[[ZincOperationQueueGroupInfo alloc] init] autorelease];
    info.className = className;
    info.maxConcurrentOperationCount = count;
    info.isBarrier = NO;
    info.queue.maxConcurrentOperationCount = info.maxConcurrentOperationCount;
    return info;
}

+ (ZincOperationQueueGroupInfo*) barrierInfoForClassName:(NSString*)className
{
    ZincOperationQueueGroupInfo* info = [[[ZincOperationQueueGroupInfo alloc] init] autorelease];
    info.className = className;
    info.maxConcurrentOperationCount = 1;
    info.isBarrier = YES;
    info.queue.maxConcurrentOperationCount = info.maxConcurrentOperationCount;
    return info;
}

- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount
{
    _maxConcurrentOperationCount = maxConcurrentOperationCount;
    if (self.queue != nil) {
        self.queue.maxConcurrentOperationCount = maxConcurrentOperationCount;
    }
}

- (void)setQueue:(NSOperationQueue *)queue
{
    [queue retain];
    [_queue release];
    _queue = queue;
    
    [_queue setMaxConcurrentOperationCount:self.maxConcurrentOperationCount];
}

- (void)dealloc
{
    [_className release];
    [_queue release];
    [super dealloc];
}

@end


@implementation ZincOperationQueueGroup

@synthesize infoByClassName = _queuesByClass;
@synthesize mySuspended = _mySuspended;

- (id)init
{
    self = [super init];
    if (self) {
        self.infoByClassName = [NSMutableDictionary dictionary];
        self.defaultQueue = [[[NSOperationQueue alloc] init] autorelease];
    }
    return self;
}

- (void)dealloc
{
    self.infoByClassName = nil;
    [super dealloc];
}


#pragma mark Entry Points
// all @synchronized

- (void) setMaxConcurrentOperationCount:(NSInteger)cnt forClass:(Class)theClass
{
    @synchronized(self) {
        NSString* className = NSStringFromClass(theClass);
        ZincOperationQueueGroupInfo* info = [ZincOperationQueueGroupInfo infoForClassName:className maxConcurrentOperationCount:cnt];
        self.infoByClassName[className] = info;
    }
}

- (void) setIsBarrierOperationForClass:(Class)theClass
{
    @synchronized(self) {
        NSString* className = NSStringFromClass(theClass);
        ZincOperationQueueGroupInfo* info = [ZincOperationQueueGroupInfo barrierInfoForClassName:className];
        self.infoByClassName[className] = info;
    }
}

- (void) addOperation:(NSOperation*)theOperation
{
    @synchronized(self) {
        ZincOperationQueueGroupInfo* info = [self infoForClass:[theOperation class]];

        NSArray* deps = nil;
        if (info != nil && info.isBarrier) {
            deps = [self getAllOperations];
        } else {
            deps = [self getAllBarrierOperations];
        }
        for (NSOperation* dep in deps) {

            // only add a new dependency if the target doesn't already depend
            // on this operation to avoid cycles

            if (![[dep zinc_allDependencies] containsObject:theOperation]) {
                [theOperation addDependency:dep];
            }
        }
        
        if (info != nil) {
            if (info.queue == nil) {
                info.queue = [[[NSOperationQueue alloc] init] autorelease];
                [info.queue setSuspended:self.isSuspended];
            }
            [info.queue addOperation:theOperation];
        } else {
            [self.defaultQueue addOperation:theOperation];
        }
    }
}

- (void)setSuspended:(BOOL)b
{
    @synchronized(self) {
        self.mySuspended = b;
        NSArray* allQueues = [self getAllQueues];
        for (NSOperationQueue* queue in allQueues) {
            [queue setSuspended:b];
        }
    }
}

- (BOOL)isSuspended
{
    return self.mySuspended;
}

- (void) suspendAndWaitForExecutingOperationsToComplete
{
    NSMutableSet* waitOps = [NSMutableSet set];
    
    @synchronized(self) {
        
        [self setSuspended:YES];
        
        NSArray* allQueues = [self getAllQueues];
        for (NSOperationQueue* queue in allQueues) {
            for (NSOperation* op in queue.operations) {
                if ([op isExecuting]) {
                    [waitOps addObject:op];
                }
            }
        }
    }
    
    for (NSOperation* op in waitOps) {
        [op waitUntilFinished];
    }
}

#pragma mark Internal Methods
// not @synchronized, only called from Entry Point methods

- (ZincOperationQueueGroupInfo*) infoForClass:(Class)theClass
{
    NSString* className = NSStringFromClass(theClass);
    return (self.infoByClassName)[className];
}

- (NSArray*) getAllQueues
{
    NSMutableArray* allQueues = [NSMutableArray arrayWithObject:self.defaultQueue];
    NSArray* allInfos = [self.infoByClassName allValues];
    for (ZincOperationQueueGroupInfo* info in allInfos) {
        if (info.queue != nil) {
            [allQueues addObject:info.queue];
        }
    }
    return allQueues;
}

- (NSArray*) getAllOperations
{
    NSMutableArray* ops = [NSMutableArray array];
    NSArray* allInfos = [self.infoByClassName allValues];
    for (ZincOperationQueueGroupInfo* info in allInfos) {
        if (info.queue != nil) {
            [ops addObjectsFromArray:info.queue.operations];
        }
    }
    return ops;
}

- (NSArray*) getAllBarrierOperations
{
    NSMutableArray* ops = [NSMutableArray array];
    NSArray* barrierInfos = [[self.infoByClassName allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return ((ZincOperationQueueGroupInfo*)evaluatedObject).isBarrier;
    }]];
    for (ZincOperationQueueGroupInfo* info in barrierInfos) {
        if (info.queue != nil) {
            [ops addObjectsFromArray:info.queue.operations];
        }
    }
    return ops;
}

@end
