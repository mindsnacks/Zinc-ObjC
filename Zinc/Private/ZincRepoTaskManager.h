//
//  ZincRepoTaskManager.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 5/13/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZincURLSessionNSURLConnectionImpl.h"

@class ZincRepo;
@class ZincTask;
@class ZincTaskDescriptor;
@class ZincTaskRef;
@class ZincTaskRequest;

@interface ZincRepoTaskManager : NSObject

- (id) initWithZincRepo:(ZincRepo*)zincRepo networkOperationQueue:(NSOperationQueue*)networkQueue;

@property (nonatomic, weak) ZincRepo* repo;


#pragma mark Task Control

- (void) suspendAllTasks;
- (void) suspendAllTasksAndWaitExecutingTasksToComplete;
- (void) resumeAllTasks;
- (BOOL) isSuspended;

#pragma mark Tasks

@property (atomic, readonly, strong) NSMutableArray* tasks;

- (NSArray*) tasksForBundleID:(NSString*)bundleID;

- (ZincTask*) queueIndexSaveTask;

#pragma mark -

/**

 @discussion Internal method to queue or get a task.

 @param taskDescriptor Descriptor describing the task to be queued. Will attempt to get an existing task if present
 @param input Abritrary data to pass to the task, akin to `userInfo`
 @param parent If not nil, the task will be added as a dependency to parent, i.e., `[parent addDependency:task]`
 @param dependencies Additional dependencies of the task. i.e., `[task addDependency:dep]`

 */
//- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input priority:(NSOperationQueuePriority)priority parent:(NSOperation*)parent dependencies:(NSArray*)dependencies;

- (ZincTask*) queueTaskWithRequestBlock:(void (^)(ZincTaskRequest* request))requestBlock;

- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor *)taskDescriptor;

- (void) addOperation:(NSOperation*)operation;

/**
 @discussion default is YES
 */
@property (atomic, assign) BOOL executeTasksInBackgroundEnabled;

#pragma mark Initialization;

- (ZincTaskRef*) taskRefForInitialization;

@end


@interface ZincRepoTaskManager (ZincURLSessionBackgroundTaskDelegate) <ZincURLSessionBackgroundTaskDelegate>

- (BOOL)urlSession:(ZincURLSessionNSURLConnectionImpl *)urlSession shouldExecuteOperationsInBackground:(ZincHTTPURLConnectionOperation *)operation;

@end
