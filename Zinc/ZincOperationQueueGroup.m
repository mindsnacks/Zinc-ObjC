//
//  ZincOperationQueueGroup.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperationQueueGroup+Private.h"
#import "NSOperation+Zinc.h"
#import "ZincChildren.h"

@interface ZincOperationQueueGroup ()
@property (atomic, strong) NSMutableDictionary* infoByClassName;
@property (atomic) BOOL mySuspended;
@property (atomic, strong) NSOperationQueue* defaultQueue;
@end

@interface ZincOperationQueueGroupInfo : NSObject
@property (nonatomic, strong) NSString* className;
@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;
@property (nonatomic, assign) BOOL isBarrier;
@property (nonatomic, strong) NSOperationQueue* queue;
@end

@implementation ZincOperationQueueGroupInfo

+ (ZincOperationQueueGroupInfo*) infoForClassName:(NSString*)className maxConcurrentOperationCount:(NSInteger)count
{
    ZincOperationQueueGroupInfo* info = [[ZincOperationQueueGroupInfo alloc] init];
    info.className = className;
    info.maxConcurrentOperationCount = count;
    info.isBarrier = NO;
    info.queue.maxConcurrentOperationCount = info.maxConcurrentOperationCount;
    return info;
}

+ (ZincOperationQueueGroupInfo*) barrierInfoForClassName:(NSString*)className
{
    ZincOperationQueueGroupInfo* info = [[ZincOperationQueueGroupInfo alloc] init];
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
    _queue = queue;
    
    [_queue setMaxConcurrentOperationCount:self.maxConcurrentOperationCount];
}


@end


@implementation ZincOperationQueueGroup

- (id)init
{
    self = [super init];
    if (self) {
        self.infoByClassName = [NSMutableDictionary dictionary];
        self.defaultQueue = [[NSOperationQueue alloc] init];
        [self setSuspended:YES];
    }
    return self;
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

- (NSArray*) getDependenciesForOperationWithInfo:(ZincOperationQueueGroupInfo*)info
{
    NSArray* deps = nil;
    if (info != nil && info.isBarrier) {
        deps = [self getAllOperations];
    } else {
        deps = [self getAllBarrierOperations];
    }
    return deps;
}

- (void) addOperation:(NSOperation*)theOperation
{
    @synchronized(self) {

        NSOperationQueue* queue = [self getQueueForClass:[theOperation class]];
        if (![[queue operations] containsObject:theOperation]) {

            ZincOperationQueueGroupInfo* info = [self infoForClass:[theOperation class]];
            NSArray* possibleDeps = [self getDependenciesForOperationWithInfo:info];

            for (NSOperation* possibleDep in possibleDeps) {
                // only add a new dependency if the target doesn't already depend
                // on this operation *or any of it's children* to avoid cycles
                // TODO: THIS IS SPARTA!!

                NSMutableSet* existingDepsAndChildrenOfPossibleDep = [NSMutableSet set];

                NSSet* allDepsOfPossibleDep = [possibleDep zinc_allDependencies];
                [existingDepsAndChildrenOfPossibleDep addObjectsFromArray:[allDepsOfPossibleDep allObjects]];

                for (NSOperation* depOfPossibleDep in allDepsOfPossibleDep) {
                    if ([depOfPossibleDep conformsToProtocol:@protocol(ZincChildren)]) {
                        [existingDepsAndChildrenOfPossibleDep addObjectsFromArray:[(id<ZincChildren>)depOfPossibleDep allChildren]];
                    }
                }

                if (![existingDepsAndChildrenOfPossibleDep containsObject:theOperation]) {
                    [theOperation addDependency:possibleDep];
                }
            }

            [queue addOperation:theOperation];
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

- (NSOperationQueue*) getQueueForClass:(Class)cls
{
    ZincOperationQueueGroupInfo* info = [self infoForClass:cls];
    if (info == nil) {
        return self.defaultQueue;
    } else {
        if (info.queue == nil) {
            info.queue = [[NSOperationQueue alloc] init];
            [info.queue setSuspended:self.isSuspended];
        }
        return info.queue;

    }
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
