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
@property (nonatomic, strong, readwrite) ZincTaskRef* taskRef;
@property (nonatomic, assign, readwrite) long long currentProgressValue;
@property (nonatomic, assign, readwrite) long long maxProgressValue;
@property (nonatomic, assign, readwrite) float progress;
@end


static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";

@implementation ZincTaskMonitor

@synthesize completionBlock = _completionBlock;
@synthesize currentProgressValue = _currentProgressValue;
@synthesize maxProgressValue = _maxProgressValue;
@synthesize progress = _progress;

- (id) initWithTaskRef:(ZincTaskRef*)taskRef;
{
    self = [super init];
    if (self) {
        _taskRef = taskRef;
    }
    return self;
}

+ (ZincTaskMonitor*) taskMonitorForTaskRef:(ZincTaskRef*)taskRef
{
    return [[[self class] alloc] initWithTaskRef:taskRef];
}

- (void)dealloc
{
    [self stopMonitoring];
    
}

- (void) monitoringDidStart
{
    [self.taskRef addObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_taskIsFinished];
}

- (void) monitoringDidStop
{
    [self.taskRef removeObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) context:&kvo_taskIsFinished];
}

- (void) callProgressBlock
{
    if (self.progressBlock != nil) {
        self.progressBlock(self, self.currentProgressValue, self.maxProgressValue, self.progress);
    }
}

- (void) callCompletionBlock
{
    if (self.completionBlock != nil) {
        self.completionBlock([self.taskRef allErrors]);
        self.completionBlock = nil;
    }
}

- (void) update
{
    self.maxProgressValue = [self.taskRef maxProgressValue];
    self.currentProgressValue = [self.taskRef isFinished] ? self.maxProgressValue : self.taskRef.currentProgressValue;
    self.progress = ZincProgressCalculate(self);
    
    [self callProgressBlock];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ZincActivityMonitorRefreshedNotification object:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kvo_taskIsFinished) {
        BOOL finished = [change[NSKeyValueChangeNewKey] boolValue];
        if (finished) {
            [self update];
            [self callCompletionBlock];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
