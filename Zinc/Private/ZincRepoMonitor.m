//
//  ZincActivityMonitor.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepoMonitor.h"

#import "ZincActivityMonitor+Private.h"
#import "ZincRepo.h"
#import "ZincTask.h"
#import "ZincResource.h"

// For Convenience Constructors
#import "ZincTaskDescriptor.h"
#import "ZincTaskActions.h"

@interface ZincRepoMonitor ()
@property (nonatomic, readwrite, strong) ZincRepo* repo;
@property (nonatomic, readwrite, strong) NSPredicate* taskPredicate;
@end


@implementation ZincRepoMonitor

- (id)initWithRepo:(ZincRepo*)repo taskPredicate:(NSPredicate*)taskPredicate
{
    self = [super init];
    if (self) {
        _repo = repo;
        _taskPredicate = taskPredicate;
    }
    return self;
}

+ (ZincRepoMonitor*) repoMonitorForBundleCloneTasksInRepo:(ZincRepo*)repo
{
    NSPredicate* pred = [NSPredicate predicateWithBlock:
                         ^BOOL(id evaluatedObject, NSDictionary *bindings) {
                             
                             ZincTask* task = (ZincTask*)evaluatedObject;
                             
                             if (![task.taskDescriptor.resource isZincBundleResource])
                                 return NO;
                             
                             if (![task.taskDescriptor.action isEqualToString:ZincTaskActionUpdate])
                                 return NO;
                             
                             return YES;
                         }];
    
    return [[self alloc] initWithRepo:repo taskPredicate:pred];
}

- (void) monitoringDidStart
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskAdded:)
                                                 name:ZincRepoTaskAddedNotification
                                               object:self.repo];
        
    NSArray* tasks = self.repo.tasks;
    for (ZincTask* task in tasks) {
        if (self.taskPredicate == nil || [self.taskPredicate evaluateWithObject:task]) {
            ZincActivityItem* item = [[ZincActivityItem alloc] initWithActivityMonitor:self subject:task];
            [self addItem:item];
        }
    }
}

- (void) monitoringDidStop
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ZincRepoTaskAddedNotification
                                                  object:self.repo];
}

- (void) itemsDidUpdate
{
    NSArray* finishedItems = [self finishedItems];
    for (ZincActivityItem* item in finishedItems) {
        [self removeItem:item];
    }
}

- (void) addTask:(ZincTask*)task
{
    ZincActivityItem* item = [[ZincActivityItem alloc] initWithActivityMonitor:self subject:task];
    [self addItem:item];
}

- (void) taskAdded:(NSNotification*)note
{
    ZincTask* task = [note userInfo][ZincRepoTaskNotificationTaskKey];
    
    if ([self.taskPredicate evaluateWithObject:task]) {
        [self addTask:task];
    }
}

@end

