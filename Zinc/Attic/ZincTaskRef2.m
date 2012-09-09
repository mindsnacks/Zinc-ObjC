//
//  ZincTaskRef2.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/3/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTaskRef2.h"
#import "ZincTask.h"

@interface ZincTaskRef2 ()
@property (nonatomic, retain) ZincTask* task;
@property (nonatomic, copy) ZincTaskProgressBlock progressBlock;
@property (atomic, assign) long long currentProgressValue;
@property (atomic, assign) long long maxProgressValue;
@end

static NSString* kvo_taskCurrentProgressValue = @"kvo_taskCurrentProgressValue";
static NSString* kvo_taskMaxProgressValue = @"kvo_taskMaxProgressValue";
static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";


@implementation ZincTaskRef2

@synthesize task = _task;
@synthesize currentProgressValue = _currentProgressValue;
@synthesize maxProgressValue = _maxProgressValue;
@synthesize progress;
@synthesize progressBlock = _progressBlock;

- (id) initWithTask:(ZincTask*) task
{
    self = [super init];
    if (self) {
        self.task = task;
    }
    return self;
}

- (void)setTask:(ZincTask *)task
{
    if (_task != nil) {
        [_task removeObserver:self forKeyPath:NSStringFromSelector(@selector(currentProgressValue)) context:&kvo_taskCurrentProgressValue];
        [_task removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxProgressValue)) context:&kvo_taskMaxProgressValue];
        [_task removeObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) context:&kvo_taskIsFinished];
        [self removeDependency:_task];
    }
    
    [task retain];
    [_task release];
    _task = task;
    
    [_task addObserver:self forKeyPath:NSStringFromSelector(@selector(currentProgressValue)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_taskCurrentProgressValue];
    [_task addObserver:self forKeyPath:NSStringFromSelector(@selector(maxProgressValue)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_taskMaxProgressValue];
    [_task addObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_taskIsFinished];
    [self addDependency:_task];
}

- (void)dealloc
{
    self.task = nil;
    self.progressBlock = nil;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kvo_taskCurrentProgressValue || context == &kvo_taskMaxProgressValue) {

        [self willChangeValueForKey:NSStringFromSelector(@selector(progress))];
        [self setValue:[change objectForKey:NSKeyValueChangeNewKey] forKey:keyPath];
        [self didChangeValueForKey:NSStringFromSelector(@selector(progress))];
        
        [self callProgressBlock];
        
    } else if (context == &kvo_taskIsFinished) {
        
        BOOL finished = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (finished) {
            self.currentProgressValue = self.maxProgressValue;
            [self callProgressBlock];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
