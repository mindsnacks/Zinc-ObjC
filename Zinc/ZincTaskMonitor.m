//
//  ZincTaskMonitor.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTaskMonitor.h"
#import "ZincActivityMonitor+Private.h"
#import "ZincTaskRef.h"


@interface ZincTaskMonitor ()
@property (nonatomic, strong, readwrite) NSArray* taskRefs;
@property (nonatomic, assign) BOOL observingIsFinished;
@end


static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";


@implementation ZincTaskMonitor

- (id) initWithTaskRefs:(NSArray*)taskRefs
{
    NSParameterAssert(taskRefs);
    self = [super init];
    if (self) {
        _taskRefs = taskRefs;

        for (ZincTaskRef* taskRef in taskRefs) {
            ZincActivityItem* item = [[ZincActivityItem alloc] initWithActivityMonitor:self operation:taskRef];
            [self addItem:item];
        }
    }
    return self;
}

+ (instancetype) taskMonitorForTaskRef:(ZincTaskRef*)taskRef
{
    return [[[self class] alloc] initWithTaskRefs:@[taskRef]];
}

- (void)dealloc
{
    [self stopMonitoring];
}

- (void) monitoringDidStart
{
    if (!self.observingIsFinished) {
        for (ZincTaskRef* taskRef in self.taskRefs) {
            [taskRef addObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_taskIsFinished];
        }
        self.observingIsFinished = YES;
    }
}

- (void) monitoringDidStop
{
    if (self.observingIsFinished) {
        for (ZincTaskRef* taskRef in self.taskRefs) {
            [taskRef removeObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) context:&kvo_taskIsFinished];
        }
        self.observingIsFinished = NO;
    }
}

- (NSArray*) allErrors
{
    NSMutableArray* errors = [NSMutableArray array];
    for (ZincTaskRef* taskRef in self.taskRefs) {
        [errors addObjectsFromArray:[taskRef allErrors]];
    }
    return errors;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kvo_taskIsFinished) {
        BOOL finished = [change[NSKeyValueChangeNewKey] boolValue];
        if (finished) {
            [self update];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
