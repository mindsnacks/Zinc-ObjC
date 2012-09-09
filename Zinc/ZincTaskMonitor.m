//
//  ZincTaskMonitor.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTaskMonitor.h"
#import "ZincTaskRef.h"
#import "ZincTask.h" // TODO: remove dependency?

@interface ZincTaskMonitor ()
@property (nonatomic, retain, readwrite) ZincTaskRef* taskRef;
@property (nonatomic, retain) NSTimer* refreshTimer;
@property (nonatomic, readwrite, assign) BOOL isMonitoring;
@end


static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";

@implementation ZincTaskMonitor

@synthesize refreshInterval = _refreshInterval;
@synthesize progressBlock = _progressBlock;
@synthesize completionBlock = _completionBlock;
@synthesize refreshTimer = _refreshTimer;
@synthesize currentProgressValue = _currentProgressValue;
@synthesize maxProgressValue = _maxProgressValue;
@dynamic progress;

- (id) initWithTaskRef:(ZincTaskRef*)taskRef;
{
    self = [super init];
    if (self) {
        _taskRef = [taskRef retain];
        _refreshInterval = kZincTaskMonitorDefaultRefreshInterval;
    }
    return self;
}

+ (ZincTaskMonitor*) taskMonitorForTaskRef:(ZincTaskRef*)taskRef
{
    return [[[[self class] alloc] initWithTaskRef:taskRef] autorelease];
}

- (void)dealloc
{
    [self stopMonitoring];
    
    [_progressBlock release];
    [_completionBlock release];
    [_taskRef release];
    [super dealloc];
}

- (void)restartRefreshTimer
{
    [self stopRefreshTimer];
    
    if (!self.isMonitoring) return;
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval
                                                         target:self
                                                       selector:@selector(updateProgress)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)stopRefreshTimer
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void) startMonitoring
{
    @synchronized(self) {
        if (self.isMonitoring) return;
        self.isMonitoring = YES;
        [self restartRefreshTimer];
        [self.taskRef addObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_taskIsFinished];
    }
}

- (void) stopMonitoring
{
    @synchronized(self) {
        if (!self.isMonitoring) return;
        self.isMonitoring = NO;
        [self stopRefreshTimer];
        [self.taskRef removeObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) context:&kvo_taskIsFinished];
    }
}

- (float) progress
{
    NSInteger max = [self maxProgressValue];
    if (max > 0.0f) {
        return (float)self.currentProgressValue / max;
    }
    return 0.0f;
}

- (void) callProgressBlock
{
    if (self.progressBlock != nil) {
        self.progressBlock(self.currentProgressValue, self.maxProgressValue, self.progress);
    }
}

- (void) callCompletionBlock
{
    if (self.completionBlock != nil) {
        self.completionBlock([self.taskRef allErrors]);
    }
}

- (void) updateProgress
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(progress))];
    self.maxProgressValue = [self.taskRef maxProgressValue];
    self.currentProgressValue = [self.taskRef isFinished] ? self.maxProgressValue : self.taskRef.currentProgressValue;
    [self didChangeValueForKey:NSStringFromSelector(@selector(progress))];
    
    [self callProgressBlock];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kvo_taskIsFinished) {
        BOOL finished = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (finished) {
            [self updateProgress];
            [self callCompletionBlock];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
