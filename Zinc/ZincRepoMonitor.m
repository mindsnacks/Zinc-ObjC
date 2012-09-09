//
//  ZincActivityMonitor.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepoMonitor.h"
#import "ZincRepo.h"
#import "ZincTask.h"
#import "ZincResource.h"

@interface ZincRepoMonitor ()
@property (nonatomic, readwrite, retain) ZincRepo* repo;
@property (nonatomic, readwrite, retain) NSPredicate* taskPredicate;
@property (nonatomic, retain) NSMutableArray* tasks;
@property (nonatomic, assign) BOOL watchForNewTasks;
@end

static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";

@implementation ZincRepoMonitor

@synthesize repo = _repo;
@synthesize taskPredicate = _taskPredicate;
@synthesize tasks = _tasks;
@synthesize watchForNewTasks = _watchForNewTasks;

- (id)initWithRepo:(ZincRepo*)repo taskPredicate:(NSPredicate*)taskPredicate
{
    self = [super init];
    if (self) {
        _repo = [repo retain];
        _taskPredicate = [taskPredicate retain];
        _tasks = [[NSMutableArray alloc] initWithCapacity:20];
        
        
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(taskFinished:)
//                                                     name:ZincRepoTaskFinishedNotification
//                                                   object:_repo];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_tasks release];
    [_repo release];
    [_taskPredicate release];
    [super dealloc];
}

- (void) startMonitoring
{
    [self startMonitoringAndWatchForNewTasks:NO];
}

- (void) startMonitoringAndWatchForNewTasks:(BOOL)watchForNewTasks
{
    self.watchForNewTasks = watchForNewTasks;
    [super startMonitoring];
}

- (void) monitoringDidStart
{
    if (self.watchForNewTasks) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(taskAdded:)
                                                     name:ZincRepoTaskAddedNotification
                                                   object:_repo];
    }
    
    // TODO: add all existing tasks
}

- (void) addTask:(ZincTask*)task
{
    @synchronized(self.tasks) {
        [self.tasks addObject:task];
        [task addObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_taskIsFinished];
    }
}

- (void) removeTask:(ZincTask*)task
{
    @synchronized(self.tasks) {
        [task removeObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) context:&kvo_taskIsFinished];
        [self.tasks removeObject:task];
    }
}

- (void) taskAdded:(NSNotification*)note
{
    ZincTask* task = [[note userInfo] objectForKey:ZincRepoTaskNotificationTaskKey];
    
    if ([self.taskPredicate evaluateWithObject:task]) {
        @synchronized(self.tasks) {
            [self.tasks addObject:task];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kvo_taskIsFinished) {
        BOOL finished = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (finished) {
            [self removeTask:object];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


@end

