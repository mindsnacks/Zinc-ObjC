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
@property (nonatomic, readwrite, retain) ZincRepo* repo;
@property (nonatomic, readwrite, retain) NSPredicate* taskPredicate;
@property (nonatomic, retain) NSMutableArray* myItems;
@end


@implementation ZincRepoMonitor

@synthesize repo = _repo;
@synthesize taskPredicate = _taskPredicate;
@synthesize myItems = _myItems;

- (id)initWithRepo:(ZincRepo*)repo taskPredicate:(NSPredicate*)taskPredicate
{
    self = [super init];
    if (self) {
        _repo = [repo retain];
        _taskPredicate = [taskPredicate retain];
        _myItems = [[NSMutableArray alloc] initWithCapacity:20];
    }
    return self;
}

- (void)dealloc
{
    [_myItems release];
    [_repo release];
    [_taskPredicate release];
    [super dealloc];
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
    
    return [[[self alloc] initWithRepo:repo taskPredicate:pred] autorelease];
}

- (NSArray*) items
{
    return [NSArray arrayWithArray:self.myItems];
}

- (void) monitoringDidStart
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskAdded:)
                                                 name:ZincRepoTaskAddedNotification
                                               object:_repo];
        
    @synchronized(self.myItems) {

        NSArray* tasks = self.repo.tasks;
        for (ZincTask* task in tasks) {
            if ([self.taskPredicate evaluateWithObject:task]) {
                ZincActivityItem* item = [[[ZincActivityItem alloc] initWithActivityMonitor:self] autorelease];
                item.task = task;
                [self.myItems addObject:item];
            }
        }
    }
}

- (void) monitoringDidStop
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) update
{
    [[self items] makeObjectsPerformSelector:@selector(update)];
   
    NSArray* finishedItems = [[self items] filteredArrayUsingPredicate:
                              [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isFinished];
    }]];
    
    @synchronized(self.myItems) {

        for (ZincActivityItem* item in finishedItems) {
            [self.myItems removeObject:item];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ZincActivityMonitorRefreshedNotification object:self];
}

- (void) addTask:(ZincTask*)task
{
    @synchronized(self.myItems) {
        ZincActivityItem* item = [[[ZincActivityItem alloc] initWithActivityMonitor:self] autorelease];
        item.task = task;
        [self.myItems addObject:item];
        //        [task addObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_taskIsFinished];
    }
}

- (void) taskAdded:(NSNotification*)note
{
    ZincTask* task = [[note userInfo] objectForKey:ZincRepoTaskNotificationTaskKey];
    
    if ([self.taskPredicate evaluateWithObject:task]) {
        [self addTask:task];
    }
}

@end

