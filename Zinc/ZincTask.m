//
//  ZincTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"
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
@property (nonatomic, retain) NSMutableArray* myEvents;
@property (readwrite, nonatomic, assign) ZincBackgroundTaskIdentifier backgroundTaskIdentifier;
@end

static const NSString* kvo_CurrentProgress = @"kvo_CurrentProgress";
static const NSString* kvo_MaxProgress = @"kvo_MaxProgress";
static const NSString* kvo_SubtaskIsFinished = @"kvo_SubtaskIsFinished";

@implementation ZincTask

@synthesize repo = _repo;
@synthesize resource = _resource;
@synthesize input = _input;
@synthesize myEvents = _myEvents;
@synthesize title = _title;
@synthesize finishedSuccessfully = _finishedSuccessfully;
@synthesize backgroundTaskIdentifier = _backgroundTaskIdentifier;

- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input
{
    self = [super init];
    if (self) {
        self.repo = repo;
        self.resource = resource;
        self.input = input;
        self.myEvents = [NSMutableArray array];
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
    
    for (ZincTask* subtask in self.subtasks) {
        [subtask setQueuePriority:p];
    }
}

- (ZincTask*) queueSubtaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor
{
    return [self queueSubtaskForDescriptor:taskDescriptor input:nil];
}

- (ZincTask*) queueSubtaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input
{
    if (self.isCancelled) return nil;
    
    ZincTask* task = [self.repo queueTaskForDescriptor:taskDescriptor input:input dependencies:nil];
    [self addDependency:task];
    [task addObserver:self forKeyPath:@"currentProgressValue" options:0 context:&kvo_CurrentProgress];
    [task addObserver:self forKeyPath:@"maxProgressValue" options:0 context:&kvo_MaxProgress];
    [task addObserver:self forKeyPath:@"isFinished" options:0 context:&kvo_SubtaskIsFinished];

    return task;
}

- (void) addOperation:(NSOperation*)operation
{
    @synchronized(self) {
        
        if (self.isCancelled) return;
        
        operation.queuePriority = self.queuePriority;
        [self addDependency:operation];
        [self.repo addOperation:operation];
    }
}

- (NSArray*) subtasks
{
    return [self.dependencies filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^(id obj, NSDictionary* bindings) {
        return [obj isKindOfClass:[ZincTask class]];
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

- (NSArray*) getAllEvents
{
    NSMutableArray* allEvents = [NSMutableArray array];
    for (ZincTask* task in self.subtasks) {
        [allEvents addObjectsFromArray:[task events]];
    }
    [allEvents addObjectsFromArray:self.myEvents];
    
    NSSortDescriptor* timestampSort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    return [allEvents sortedArrayUsingDescriptors:[NSArray arrayWithObject:timestampSort]];
}

- (NSArray*) getAllErrors
{
    NSArray* allEvents = [self getAllEvents];
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

#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (void)setShouldExecuteAsBackgroundTask
{
    if (!self.backgroundTaskIdentifier) {
        UIApplication *application = [UIApplication sharedApplication];
        self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
            
            [self cancel];
            
            [application endBackgroundTask:self.backgroundTaskIdentifier];
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];
    }
}
#endif

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kvo_CurrentProgress) {
        [self willChangeValueForKey:@"currentProgressValue"];
        [self willChangeValueForKey:@"progress"];
        [self didChangeValueForKey:@"currentProgressValue"];
        [self didChangeValueForKey:@"progress"];
        //NSLog(@"progress: %f", self.progress);
    } else if (context == &kvo_MaxProgress) {
        [self willChangeValueForKey:@"maxProgressValue"];
        [self willChangeValueForKey:@"progress"];
        [self didChangeValueForKey:@"maxProgressValue"];
        [self didChangeValueForKey:@"progress"];
        //NSLog(@"progress: %f", self.progress);
    } else if (context == &kvo_SubtaskIsFinished) {
        [object removeObserver:self forKeyPath:@"currentProgressValue" context:&kvo_CurrentProgress];
        [object removeObserver:self forKeyPath:@"maxProgressValue" context:&kvo_MaxProgress];
        [object removeObserver:self forKeyPath:@"isFinished" context:&kvo_SubtaskIsFinished];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
