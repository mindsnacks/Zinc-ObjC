//
//  ZincTaskRef2.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/3/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleCloneMonitor.h"
#import "ZincTask.h"
#import "ZincEvent.h"
#import "ZincRepo.h"
#import "ZincResource.h"

@interface ZincBundleCloneMonitor ()
- (id) initWithRepo:(ZincRepo*)repo bundleID:(NSString*)bundleId;
@property (nonatomic, readwrite, retain) ZincRepo* repo;
@property (nonatomic, readwrite, retain) NSString* bundleID;
@property (nonatomic, retain) ZincTask* task;
@property (atomic, assign) long long currentProgressValue;
@property (atomic, assign) long long maxProgressValue;
@property (nonatomic, retain) NSTimer* refreshTimer;
@end

//static NSString* kvo_taskCurrentProgressValue = @"kvo_taskCurrentProgressValue";
//static NSString* kvo_taskMaxProgressValue = @"kvo_taskMaxProgressValue";
static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";


@implementation ZincBundleCloneMonitor

@synthesize repo = _repo;
@synthesize task = _task;
@synthesize isMonitoring = _isMonitoring;
@synthesize refreshInterval = _refreshInterval;
@synthesize currentProgressValue = _currentProgressValue;
@synthesize maxProgressValue = _maxProgressValue;
@dynamic progress;
@synthesize progressBlock = _progressBlock;
@synthesize completionBlock = _completionBlock;
@synthesize refreshTimer = _refreshTimer;

//- (id) initWithTask:(ZincTask*) task
//{
//    self = [super init];
//    if (self) {
//        self.task = task;
//    }
//    return self;
//}

+ (ZincBundleCloneMonitor*)bundleCloneMonitorWithRepo:(ZincRepo*)repo
                                             bundleID:(NSString*)bundleId
{
    ZincBundleCloneMonitor* monitor = [[[ZincBundleCloneMonitor alloc] initWithRepo:repo bundleID:bundleId] autorelease];
    return monitor;
}

- (id) initWithRepo:(ZincRepo*)repo bundleID:(NSString*)bundleID
{
    self = [super init];
    if (self) {
        _repo = [repo retain];
        _bundleID = [bundleID retain];
        _refreshInterval = kZincBundleCloneMonitorDefaultRefreshInterval;
        _isMonitoring = NO;
    }
    return self;
}

- (void)restartRefreshTimer
{
    [self stopRefreshTimer];
    
    if (!self.isMonitoring) return;
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval
                                                         target:self
                                                       selector:@selector(refreshTimerFired:)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)stopRefreshTimer
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void)startMonitoring
{
    if (self.isMonitoring) return;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cloneBeginNotification:)
                                                 name:kZincEventBundleCloneBeginNotification
                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(cloneCompleteNotification:)
//                                                 name:kZincEventBundleCloneCompleteNotification
//                                               object:nil];
    
    [self restartRefreshTimer];
    
}


- (void)stopMonitoring
{
    if (!self.isMonitoring) return;
    
    [self stopRefreshTimer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kZincEventBundleCloneBeginNotification
                                                  object:nil];
}

- (void)getTask
{
    if (self.task == nil)
    {
        for (ZincTask *task in self.repo.tasks)
        {
            if ([task.resource.zincBundleId isEqualToString:self.bundleID])
            {
                self.task = task;
                break;
            }
        }
    }
}

- (void)cloneBeginNotification:(NSNotification *)note
{
    if (self.task == nil)
    {
        NSString *notificationBundleIdentifier = [note.userInfo valueForKey:kZincEventAttributesContextKey];

        if ([notificationBundleIdentifier isEqualToString:self.bundleID])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self getTask];
            });
        }
    }
}

//- (void)cloneCompleteNotification:(NSNotification *)note
//{
//    if (self.task != nil)
//    {
//        NSString *bundleIdentifier = [note.userInfo valueForKey:kZincEventAttributesContextKey];
//
//        if ([bundleIdentifier isEqualToString:self.bundleIdentifier])
//        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self setProgress:1.0f];
//            });
//        }
//    }
//}

- (void)setRefreshInterval:(NSTimeInterval)refreshInterval
{
    _refreshInterval = refreshInterval;
    
    [self restartRefreshTimer];
}

- (void)setTask:(ZincTask *)task
{
    if (_task != nil) {
//        [_task removeObserver:self forKeyPath:NSStringFromSelector(@selector(currentProgressValue)) context:&kvo_taskCurrentProgressValue];
//        [_task removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxProgressValue)) context:&kvo_taskMaxProgressValue];
        [_task removeObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) context:&kvo_taskIsFinished];
//        [self removeDependency:_task];
    }
    
    [self stopRefreshTimer];
    
    [task retain];
    [_task release];
    _task = task;
    
    if (_task != nil) {
        
        //    [_task addObserver:self forKeyPath:NSStringFromSelector(@selector(currentProgressValue)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_taskCurrentProgressValue];
        //    [_task addObserver:self forKeyPath:NSStringFromSelector(@selector(maxProgressValue)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_taskMaxProgressValue];
        [_task addObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_taskIsFinished];
        //    [self addDependency:_task];
        
        [self restartRefreshTimer];
    }
}

- (void)dealloc
{
    [self stopMonitoring];
    
    self.repo = nil;
    self.bundleID = nil;
    self.task = nil;
    self.progressBlock = nil;
    self.completionBlock = nil;
    [super dealloc];
}

- (NSArray*) errors
{
    return [self.task getAllErrors];
}

- (NSArray*) events
{
    return [self.task getAllEvents];
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
        self.completionBlock([self errors]);
    }
}

- (void) updateProgress
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(progress))];
    self.maxProgressValue = [self.task maxProgressValue];
    self.currentProgressValue = [self.task isFinished] ? self.maxProgressValue : self.task.currentProgressValue;
    [self didChangeValueForKey:NSStringFromSelector(@selector(progress))];

    [self callProgressBlock];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    if (context == &kvo_taskCurrentProgressValue || context == &kvo_taskMaxProgressValue) {
//
//        [self willChangeValueForKey:NSStringFromSelector(@selector(progress))];
//        [self setValue:[change objectForKey:NSKeyValueChangeNewKey] forKey:keyPath];
//        [self didChangeValueForKey:NSStringFromSelector(@selector(progress))];
//        
//        [self callProgressBlock];
//        
//    } else
        
    if (context == &kvo_taskIsFinished) {
        
        BOOL finished = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (finished) {
            [self updateProgress];
            [self callCompletionBlock];
//            
//            self.currentProgressValue = self.maxProgressValue;
//            [self callProgressBlock];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
