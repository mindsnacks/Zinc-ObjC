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


@interface ZincTask ()
@property (nonatomic, retain, readwrite) NSURL* resource;
@property (nonatomic, retain, readwrite) id input;
@property (atomic, retain) NSMutableArray* myChildOperations;
@end

static NSString* kvo_isExecuting = @"kvo_isExecuting";
static NSString* kvo_isFinished = @"kvo_isFinished";


@implementation ZincTask


- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input
{
    self = [super initWithRepo:repo];
    if (self) {
        self.resource = resource;
        self.input = input;
        self.myChildOperations = [NSMutableArray array];
        
        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(isExecuting)) options:NSKeyValueObservingOptionOld |  NSKeyValueObservingOptionNew context:&kvo_isExecuting];
        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&kvo_isFinished];
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
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(isExecuting)) context:&kvo_isExecuting];
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(isFinished)) context:&kvo_isFinished];

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
        task = [self.repo queueTaskForDescriptor:taskDescriptor input:input dependencies:nil];
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


- (NSArray*) allEvents
{
    NSMutableArray* allEvents = [NSMutableArray array];
    for (ZincTask* task in self.childTasks) {
        [allEvents addObjectsFromArray:[task events]];
    }
    [allEvents addObjectsFromArray:self.events];
    
    NSSortDescriptor* timestampSort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    return [allEvents sortedArrayUsingDescriptors:[NSArray arrayWithObject:timestampSort]];
}


- (NSArray*) allErrors
{
    NSArray* allEvents = [self allEvents];
    NSMutableArray* allErrors = [NSMutableArray arrayWithCapacity:[allEvents count]];
    for (ZincEvent* event in allEvents) {
        if([event isKindOfClass:[ZincErrorEvent class]]) {
            [allErrors addObject:[(ZincErrorEvent*)event error]];
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


- (void) cancel
{
    @synchronized(self.myChildOperations) {
        [self.myChildOperations makeObjectsPerformSelector:@selector(cancel)];
    }
    
    [super cancel];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kvo_isExecuting) {
        
        if (![[change objectForKey:NSKeyValueChangeOldKey] boolValue] &&
            [[change objectForKey:NSKeyValueChangeNewKey] boolValue]) {
            
            [self addEvent:[ZincTaskBeginEvent taskBeginEventWithSource:ZINC_EVENT_SRC_OBJECT()]];
        }
        
    } else if (context == &kvo_isFinished) {
        
        if (![[change objectForKey:NSKeyValueChangeOldKey] boolValue] &&
            [[change objectForKey:NSKeyValueChangeNewKey] boolValue]) {
            
            [self addEvent:[ZincTaskCompleteEvent taskCompleteEventWithSource:ZINC_EVENT_SRC_OBJECT()]];
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
