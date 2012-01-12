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

@interface ZincTask ()
@property (nonatomic, assign, readwrite) ZincRepo* repo;
@property (nonatomic, retain, readwrite) id<ZincResourceDescriptor>* resource;
@property (nonatomic, retain) NSMutableArray* myEvents;
@end

@implementation ZincTask

@synthesize repo = _repo;
@synthesize resource = _resource;
@synthesize suboperations = _suboperations;
@synthesize supertask = _supertask;
@synthesize myEvents = _myEvents;
@synthesize title = _title;
@synthesize finishedSuccessfully = _finishedSuccessfully;

- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(id<ZincResourceDescriptor>)resource
{
    self = [super init];
    if (self) {
        self.repo = repo;
        self.resource = resource;
        self.myEvents = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc 
{
    self.suboperations = nil;
    self.myEvents = nil;
    self.repo = nil;
    self.resource = nil;
    [super dealloc];
}

- (void) cancel
{
    @synchronized(self) {
        [super cancel];
        [self.suboperations makeObjectsPerformSelector:@selector(cancel)];
    }
}

- (double) progress
{
    return -1;
}

+ (NSString*) taskMethod
{
    return NSStringFromClass(self);
}

+ (ZincTaskDescriptor*) taskDescriptorForResource:(id<ZincResourceDescriptor>)resource
{
    ZincTaskDescriptor* td = [[[ZincTaskDescriptor alloc] init] autorelease];
    td.method = [self taskMethod];
    td.resource = resource;
    return td;
}

- (ZincTaskDescriptor*) taskDescriptor
{
    return [[self class] taskDescriptorForResource:self.resource];    
}

- (void) addOperation:(NSOperation*)operation
{
    @synchronized(self) {
        
        if (self.isCancelled) return;
        
        if ([operation isKindOfClass:[ZincTask class]]) {
            ZincTask* task = (ZincTask*)operation;
            task.supertask = self;
        }
        
        [self.suboperations addObject:operation];
        [self.repo addOperation:operation];
    }
}

- (NSArray*) subtasks
{
    return [self.suboperations filteredArrayUsingPredicate:
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

- (void) addEvent:(ZincEvent*)event
{
    [self.myEvents addObject:event];
}

- (NSArray*) events
{
    return [NSArray arrayWithArray:self.myEvents];
}

@end
