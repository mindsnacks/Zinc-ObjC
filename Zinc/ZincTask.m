//
//  ZincTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"
#import "ZincTask+Private.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincTaskDescriptor.h"
#import "ZincEvent.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
typedef UIBackgroundTaskIdentifier ZincBackgroundTaskIdentifier;
#else
typedef id ZincBackgroundTaskIdentifier;
#endif

@interface ZincTask ()
@property (nonatomic, assign, readwrite) ZincRepo* repo;
@property (nonatomic, retain, readwrite) NSURL* resource;
@property (nonatomic, retain, readwrite) id input;
@property (atomic, retain) NSMutableArray* myChildOperations;
@property (atomic, retain) NSMutableArray* myEvents;
@property (readwrite, nonatomic, assign) ZincBackgroundTaskIdentifier backgroundTaskIdentifier;
@end

@implementation ZincTask

- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input
{
    self = [super init];
    if (self) {
        self.repo = repo;
        self.resource = resource;
        self.input = input;
        self.myEvents = [NSMutableArray array];
        self.myChildOperations = [NSMutableArray array];
    }
    return self;
}

- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource
{
    return [self initWithRepo:repo resourceDescriptor:resource input:nil];
}

+ (id) taskWithDescriptor:(ZincTaskDescriptor*)taskDesc repo:(ZincRepo*)repo input:(id)input
{
    Class taskClass = NSClassFromString([taskDesc method]);
    ZincTask* task = [[[taskClass alloc] initWithRepo:repo resourceDescriptor:taskDesc.resource input:input] autorelease];
    return task;
}

+ (id) taskWithDescriptor:(ZincTaskDescriptor*)taskDesc repo:(ZincRepo*)repo
{
    return [self taskWithDescriptor:taskDesc repo:repo];
}

- (void)dealloc 
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    if (_backgroundTaskIdentifier) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
#endif
    
    [_myEvents release];
    [_myChildOperations release];
    [_resource release];
    [_input release];
    [super dealloc];
}

+ (NSString *)action
{
    NSAssert(NO, @"subclasses must override");
    return nil;
}

+ (NSString*) taskMethod
{
    return NSStringFromClass(self);
}

+ (ZincTaskDescriptor*) taskDescriptorForResource:(NSURL*)resource
{
    return [ZincTaskDescriptor taskDescriptorWithResource:resource action:[self action] method:[self taskMethod]];
}

- (ZincTaskDescriptor*) taskDescriptor
{
    return [[self class] taskDescriptorForResource:self.resource];    
}

- (void) setQueuePriority:(NSOperationQueuePriority)p
{
    [super setQueuePriority:p];
    
    // !!!: Since isReady may be related to queue priority make sure to update it
    [self updateReadiness];
    
    for (NSOperation* op in self.childOperations) {
        [op setQueuePriority:p];
    }
}

- (void) addChildOperation:(NSOperation*)childOp
{
    @synchronized(self.myChildOperations) {
        [self.myChildOperations addObject:childOp];
    }
    childOp.queuePriority = self.queuePriority;
    [self addDependency:childOp];
    // childOp may already be added as a dependency if created via queueTaskForDescriptor, but it's not a problem
}

- (ZincTask*) queueChildTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor
{
    return [self queueChildTaskForDescriptor:taskDescriptor input:nil];
}

- (ZincTask*) queueChildTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input
{
    if (self.isCancelled) return nil;
    
    ZincTask* task;
    
    @synchronized(self) {
        // synchronizing on self here because there is a slight race condition. The task is created
        // and queued before it is added to myChildOperations.
        task = [self.repo queueTaskForDescriptor:taskDescriptor input:input parent:self dependencies:nil];
        [self addChildOperation:task];
    }

    return task;
}

- (void) queueChildOperation:(NSOperation*)operation
{
    if (self.isCancelled) return;
    
    [self addChildOperation:operation];
    [self.repo addOperation:operation];
}

- (NSArray*) childOperations
{
    NSArray* childOps;
    @synchronized(self) {
        // synchronizing on self here because there is a slight race condition.
        // See queueChildTaskForDescriptor:input: above
        childOps = [NSArray arrayWithArray:self.myChildOperations];
    }
    return childOps;
}

- (NSArray*) childTasks
{
    NSArray* subops = [self childOperations];
    return [subops filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isKindOfClass:[ZincTask class]];
    }]];
}

- (void) addEvent:(ZincEvent*)event
{
    [self.myEvents addObject:event];
    [self.repo logEvent:event];
}

- (NSArray*) events
{
    return [NSArray arrayWithArray:self.myEvents];
}

- (NSArray*) allEvents
{
    NSMutableArray* allEvents = [NSMutableArray array];
    for (ZincTask* task in self.childTasks) {
        [allEvents addObjectsFromArray:[task events]];
    }
    [allEvents addObjectsFromArray:self.myEvents];
    
    NSSortDescriptor* timestampSort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    return [allEvents sortedArrayUsingDescriptors:@[timestampSort]];
}

- (NSArray*) allErrors
{
    NSArray* allEvents = [self allEvents];
    NSMutableArray* allErrors = [NSMutableArray arrayWithCapacity:[allEvents count]];
    for (ZincEvent* event in allEvents) {
        if([event isKindOfClass:[ZincErrorEvent class]]) {
            NSError* error = [(ZincErrorEvent*)event error];
            if (error) {
                [allErrors addObject:error];
            }
        }
    }
    // TODO: write a test for this
    if ([allErrors count] == 0) {
        return nil;
    }
    return allErrors;
}

- (void) updateReadiness
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isReady))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(isReady))];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (void)setShouldExecuteAsBackgroundTask
{
    if (!self.backgroundTaskIdentifier) {
        
        UIApplication *application = [UIApplication sharedApplication];
        __block typeof(self) blockSelf = self;
        self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
            
            UIBackgroundTaskIdentifier backgroundTaskIdentifier =  blockSelf.backgroundTaskIdentifier;
            blockSelf.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            
            [blockSelf cancel];
            
            [application endBackgroundTask:backgroundTaskIdentifier];
        }];
    }
}
#endif

- (void) cancel
{
    @synchronized(self.myChildOperations) {
        [self.myChildOperations makeObjectsPerformSelector:@selector(cancel)];
    }
    
    [super cancel];
}

@end
