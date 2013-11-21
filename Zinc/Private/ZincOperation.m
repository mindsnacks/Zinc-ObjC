//
//  ZincOperation.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperation+Private.h"
#import "NSOperation+Zinc.h"
#import "ZincProgress.h"

double const kZincOperationInitialDefaultThreadPriority = 0.5;

double const kZincOperationDefaultReadinessUpdateInterval = 5.0;


#define DEFAULT_MAX_PROGRESS_VAL (1000)

@interface ZincOperation ()
@property (atomic, strong) NSMutableSet* myChildOperations;
@property (weak) NSTimer *updateReadinessTimer;
@end

@implementation ZincOperation

static double _defaultThreadPriority = kZincOperationInitialDefaultThreadPriority;

+ (void)setDefaultThreadPriority:(double)defaultThreadPriority
{
    @synchronized(self) {
        _defaultThreadPriority = defaultThreadPriority;
    }
}

+ (double)defaultThreadPriority
{
    return _defaultThreadPriority;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.threadPriority = [[self class] defaultThreadPriority];
        _myChildOperations = [NSMutableSet set];
        _readinessUpdateInterval = kZincOperationDefaultReadinessUpdateInterval;
    }
    return self;
}

- (void)dealloc
{
    [self stopUpdateReadinessTimer];
}

- (void)stopUpdateReadinessTimer
{
    [self.updateReadinessTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
    self.updateReadinessTimer = nil;
}

- (void)restartUpdateReadinessTimer
{
    if (self.readinessBlock != nil
        && self.readinessUpdateInterval > 0
        && ![self isFinished]
        && ![self isExecuting]) {

        [self stopUpdateReadinessTimer];

        self.updateReadinessTimer = [NSTimer timerWithTimeInterval:self.readinessUpdateInterval
                                                            target:self
                                                          selector:@selector(updateReadinessTimerFired)
                                                          userInfo:nil
                                                           repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.updateReadinessTimer forMode:NSRunLoopCommonModes];
    }
}

- (void) updateReadinessTimerFired
{
    if (self.isExecuting || self.isFinished) {
        [self stopUpdateReadinessTimer];
    } else {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isReady))];
        [self didChangeValueForKey:NSStringFromSelector(@selector(isReady))];
    }
}

- (BOOL) isReady
{
    if (self.readinessBlock != nil) {
        return [super isReady] && self.readinessBlock();
    } else {
        return [super isReady];
    }
}

- (void)setReadinessBlock:(BOOL (^)(void))readinessBlock
{
    [self stopUpdateReadinessTimer];

    _readinessBlock = [readinessBlock copy];

    [self restartUpdateReadinessTimer];
}

- (void)setReadinessUpdateInterval:(NSTimeInterval)readinessUpdateInterval
{
    [self stopUpdateReadinessTimer];

    _readinessUpdateInterval = readinessUpdateInterval;

    [self restartUpdateReadinessTimer];
}

- (NSArray*) zincDependencies
{
    return [self.dependencies filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^(id obj, NSDictionary* bindings) {
        return [obj isKindOfClass:[ZincOperation class]];
    }]];
}

- (long long) currentProgressValue
{
    if ([self isFinished]) {
        return [self maxProgressValue];
    } else {
        return 0;
    }
}

- (long long) maxProgressValue
{
    return DEFAULT_MAX_PROGRESS_VAL;
}

- (id<ZincProgress>)progress
{
    NSArray* items = [[[self allChildren] arrayByAddingObject:self] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject conformsToProtocol:@protocol(ZincProgress)];
    }]];
    return ZincAggregatedProgressCalculate(items);
}

- (void) addDependency:(NSOperation *)op
{
    NSAssert(![[op zinc_allDependencies] containsObject:self], @"attempt to add circular dependency\n  Operation: %@\n  Dependency: %@", self, op);
    [super addDependency:op];
}

- (NSArray*) immediateChildren
{
    NSArray* childOps;
    @synchronized(self) {
        childOps = [self.myChildOperations allObjects];
    }
    return childOps;
}

- (NSArray*) allChildren
{
    NSArray* myChildren = [self immediateChildren];
    NSMutableSet* allChildren = [NSMutableSet setWithArray:myChildren];
    for (NSOperation* child in myChildren) {
        if ([child conformsToProtocol:@protocol(ZincChildren)]) {
            [allChildren addObjectsFromArray:[(id<ZincChildren>)child allChildren]];
        }
    }
    return [allChildren allObjects];
}

- (void) addChildOperation:(NSOperation*)childOp
{
    @synchronized(self.myChildOperations) {
        [self.myChildOperations addObject:childOp];
    }
    childOp.queuePriority = self.queuePriority;
}

- (void) cancel
{
    @synchronized(self.myChildOperations) {
        [self.myChildOperations makeObjectsPerformSelector:@selector(cancel)];
    }
    [super cancel];
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@: %p isReady=%d isExecuting=%d isFinished=%d queuePriority=%d>",
            NSStringFromClass([self class]),
            self,
            self.isReady,
            self.isExecuting,
            self.isFinished,
            self.queuePriority];
}

@end
