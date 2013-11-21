//
//  ZincRepoTaskManager.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 5/13/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincRepoTaskManager.h"

#import "ZincInternals.h"

#import "ZincRepo+Private.h"
#import "ZincTask+Private.h"
#import "ZincDownloadPolicy.h"
#import "ZincOperationQueueGroup.h"
#import "ZincHTTPRequestOperation.h"


static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";


@interface ZincRepoTaskManager ()
@property (nonatomic, strong) NSOperationQueue* networkQueue;
@property (nonatomic, strong) NSOperationQueue* internalQueue;
@property (nonatomic, strong) ZincOperationQueueGroup* taskQueueGroup;
@property (atomic, readwrite, strong) NSMutableArray* tasks;
@end


@implementation ZincRepoTaskManager

- (id) initWithZincRepo:(ZincRepo*)zincRepo networkOperationQueue:(NSOperationQueue*)networkQueue
{
    self = [super init];
    if (self) {

        self.repo = zincRepo;
        self.networkQueue = networkQueue;

        self.internalQueue = [[NSOperationQueue alloc] init];
        self.taskQueueGroup = [[ZincOperationQueueGroup alloc] init];
        [self.taskQueueGroup setIsBarrierOperationForClass:[ZincGarbageCollectTask class]];
        [self.taskQueueGroup setIsBarrierOperationForClass:[ZincBundleDeleteTask class]];
        [self.taskQueueGroup setMaxConcurrentOperationCount:2 forClass:[ZincBundleRemoteCloneTask class]];
        [self.taskQueueGroup setMaxConcurrentOperationCount:1 forClass:[ZincCatalogUpdateTask class]];
        [self.taskQueueGroup setMaxConcurrentOperationCount:kZincRepoDefaultObjectDownloadCount forClass:[ZincObjectDownloadTask class]];
        [self.taskQueueGroup setMaxConcurrentOperationCount:1 forClass:[ZincSourceUpdateTask class]];
        [self.taskQueueGroup setMaxConcurrentOperationCount:1 forClass:[ZincArchiveExtractOperation class]];

        self.tasks = [NSMutableArray array];
        self.executeTasksInBackgroundEnabled = YES;
    }
    return self;
}

#pragma mark Internal Operations

- (void) suspendAllTasks
{
    [self.taskQueueGroup setSuspended:YES];
}

- (void) suspendAllTasksAndWaitExecutingTasksToComplete
{
    [self suspendAllTasks];
    [self.taskQueueGroup suspendAndWaitForExecutingOperationsToComplete];
}

- (void) resumeAllTasks
{
    [self.taskQueueGroup setSuspended:NO];
}

- (BOOL) isSuspended
{
    return self.taskQueueGroup.isSuspended;
}

- (void) addOperation:(NSOperation*)operation
{
    if ([operation isKindOfClass:[ZincHTTPRequestOperation class]]) {
        [self.networkQueue addOperation:operation];
    } else if ([operation isKindOfClass:[ZincInitializationTask class]] ||
               [operation isKindOfClass:[ZincRepoIndexUpdateTask class]] ||
               [operation isKindOfClass:[ZincTaskRef class]]) {
        [self.internalQueue addOperation:operation];
    } else {
        [self.taskQueueGroup addOperation:operation];
    }
}

- (ZincTask*) taskForDescriptor:(ZincTaskDescriptor*)taskDescriptor
{
    @synchronized(self.tasks) {
        for (ZincTask* task in self.tasks) {
            if ([[task taskDescriptor] isEqual:taskDescriptor]) {
                return task;
            }
        }
    }
    return nil;
}

- (NSArray*) tasksForResource:(NSURL*)resource
{
    @synchronized(self.tasks) {
        NSMutableArray* tasks = [NSMutableArray array];
        for (ZincTask* task in self.tasks) {
            if ([task.resource isEqual:resource]) {
                [tasks addObject:task];
            }
        }
        return tasks;
    }
}

- (NSArray*) tasksWithMethod:(NSString*)method
{
    @synchronized(self.tasks) {
        return [self.tasks filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"method = %@", method]];
    }
}

- (NSArray*) tasksForBundleID:(NSString*)bundleID
{
    @synchronized(self.tasks) {

        NSMutableArray* tasks = [NSMutableArray array];
        for (ZincTask* task in self.tasks) {
            if ([task.resource isZincBundleResource]) {
                if ([[task.resource zincBundleID] isEqualToString:bundleID]) {
                    [tasks addObject:task];
                }
            }
        }
        return tasks;
    }
}

- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor *)taskDescriptor
{
    return [self queueTaskWithRequestBlock:^(ZincTaskRequest *request) {
        request.taskDescriptor = taskDescriptor;
    }];
}

- (ZincTask*) queueTaskForRequest:(ZincTaskRequest*)taskRequest
{
    return [self queueTaskForDescriptor:taskRequest.taskDescriptor
                                  input:taskRequest.input
                               priority:taskRequest.priority
                                 parent:taskRequest.parent
                           dependencies:taskRequest.dependencies];
}

- (ZincTask*) queueTaskWithRequestBlock:(void (^)(ZincTaskRequest* ))requestBlock
{
    ZincTaskRequest* request = [[ZincTaskRequest alloc] init];
    requestBlock(request);
    return [self queueTaskForRequest:request];
}

- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input priority:(NSOperationQueuePriority)priority parent:(ZincOperation*)parent dependencies:(NSArray*)dependencies
{
    NSAssert(parent == nil || [parent isKindOfClass:[ZincOperation class]], @"temporary assert");

    ZincTask* task = nil;

    @synchronized(self.tasks) {

        NSArray* tasksMatchingResource = [self tasksForResource:taskDescriptor.resource];

        // Check for exact match
        ZincTask* existingTask = [self taskForDescriptor:taskDescriptor];
        if (existingTask == nil) {
            // look for task that also matches the action
            for (ZincTask* potentialMatchingTask in tasksMatchingResource) {
                if ([[potentialMatchingTask taskDescriptor].action isEqual:taskDescriptor.action]) {
                    existingTask = potentialMatchingTask;
                }
            }

            // if no exact match found, add task and depends for all other resource-matching
            if (existingTask == nil) {
                task = [ZincTask taskWithDescriptor:taskDescriptor repo:self.repo input:input];
                for (ZincTask* resourceTask in tasksMatchingResource) {
                    if (resourceTask != task) {
                        [task addDependency:resourceTask];
                    }
                }
            }
        }

        if (existingTask != nil) {
            task = existingTask;
        }

        NSAssert(task, @"task is nil");

        // add dependency to parent (nil is OK)
        [parent addChildOperation:task];

        // add all explicit deps
        for (NSOperation* dep in dependencies) {
            [task addDependency:dep];
        }

        // update priority
        task.queuePriority = priority;

        // finally queue task if it was not pre-existing
        if (existingTask == nil) {
            [self queueTask:task];
        }
    }

    return task;
}

- (void) queueTask:(ZincTask*)task
{
    if (self.executeTasksInBackgroundEnabled) {
        [task setShouldExecuteAsBackgroundTask];
    }

    @synchronized(self.tasks) {
        [self.tasks addObject:task];
        [task addObserver:self forKeyPath:@"isFinished" options:0 context:&kvo_taskIsFinished];
        [self addOperation:task];
    }

    [self.repo postNotification:ZincRepoTaskAddedNotification
                       userInfo:@{ ZincRepoTaskNotificationTaskKey : task }];

}

-  (void) removeTask:(ZincTask*)task
{
    ZincTask* foundTask = nil;
    @synchronized(self.tasks) {
        foundTask = [self taskForDescriptor:[task taskDescriptor]];
        if (foundTask != nil) {
            [foundTask removeObserver:self forKeyPath:@"isFinished" context:&kvo_taskIsFinished];
            [self.tasks removeObject:foundTask];
        }
    }

    if (foundTask != nil) {
        [self.repo postNotification:ZincRepoTaskFinishedNotification
                           userInfo:@{ ZincRepoTaskNotificationTaskKey : foundTask }];
    }
}

- (ZincCompleteInitializationTask*) getCompleteInitializationTask
{
    for (NSOperationQueue* op in [self.internalQueue operations]) {
        if ([op isKindOfClass:[ZincCompleteInitializationTask class]]) {
            return (ZincCompleteInitializationTask*)op;
        }
    }
    return nil;
}

- (ZincTaskRef*) taskRefForInitialization
{
    @synchronized(self) {

        ZincCompleteInitializationTask* completeInitializationTask = [self getCompleteInitializationTask];
        if (completeInitializationTask == nil) {
        return nil;
        }

        ZincTaskRef* taskRef = [ZincTaskRef taskRefForTask:completeInitializationTask];
        [self addOperation:taskRef];
        return taskRef;
    }
}

- (ZincTask*) queueIndexSaveTask
{
    ZincTaskDescriptor* taskDesc = [ZincRepoIndexUpdateTask taskDescriptorForResource:[self.repo indexURL]];
    return [self queueTaskForDescriptor:taskDesc];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kvo_taskIsFinished) {
        ZincTask* task = (ZincTask*)object;
        if (task.isFinished) {
            [self removeTask:task];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
