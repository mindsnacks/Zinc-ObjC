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
#import "ZincEvent+Private.h"
#import "ZincTaskDescriptor.h"

@interface ZincTask ()
@property (nonatomic, assign, readwrite) ZincRepo* repo;
@property (nonatomic, retain, readwrite) NSURL* resource;
@property (nonatomic, retain, readwrite) id input;
@property (nonatomic, retain) NSMutableArray* myEvents;
@end

@implementation ZincTask

@synthesize repo = _repo;
@synthesize resource = _resource;
@synthesize input = _input;
@synthesize myEvents = _myEvents;
@synthesize title = _title;
@synthesize finishedSuccessfully = _finishedSuccessfully;

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
    self.myEvents = nil;
    self.repo = nil;
    self.resource = nil;
    self.input = nil;
    [super dealloc];
}

- (void) cancel
{
    @synchronized(self) {
        [super cancel];
        [self.dependencies makeObjectsPerformSelector:@selector(cancel)];
    }
}

- (NSInteger) currentProgressValue
{
    return [[self.subtasks valueForKeyPath:@"@sum.currentProgressValue"] integerValue];
}

- (NSInteger) maxProgressValue
{
    return [[self.subtasks valueForKeyPath:@"@sum.maxProgressValue"] integerValue];
}

- (double) progress
{
    NSInteger max = [self maxProgressValue];
    if (max > 0) {
        return (double)self.currentProgressValue / max;
    }
    return 0;
}

+ (NSString*) taskMethod
{
    return NSStringFromClass(self);
}

+ (ZincTaskDescriptor*) taskDescriptorForResource:(NSURL*)resource
{
    return [ZincTaskDescriptor taskDescriptorWithResource:resource method:[self taskMethod]];
}

- (ZincTaskDescriptor*) taskDescriptor
{
    return [[self class] taskDescriptorForResource:self.resource];    
}

- (ZincTask*) queueSubtaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor
{
    return [self queueSubtaskForDescriptor:taskDescriptor input:nil];
}

- (ZincTask*) queueSubtaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input
{
    if (self.isCancelled) return nil;
    
    ZincTask* task = [self.repo queueTaskForDescriptor:taskDescriptor input:input dependencies:[NSArray arrayWithObject:self]];
    [self addDependency:task];
    return task;
}


- (void) addOperation:(NSOperation*)operation
{
    @synchronized(self) {
        
        if (self.isCancelled) return;
        
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

//- (void) waitForSuboperations
//{
//    for (NSOperation* operation in self.suboperations) {
//        [operation waitUntilFinished];
//    }
//}

- (void)postEventNotification:(ZincEvent *)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:[[event class] notificationName] object:self.repo userInfo:event.attributes];
}

- (void) addEvent:(ZincEvent*)event
{
    [self.myEvents addObject:event];
    
    [self postEventNotification:event];
    
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

@end
