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

@interface ZincTask ()
@property (nonatomic, assign, readwrite) ZincRepo* repo;
@property (nonatomic, retain) NSMutableArray* myEvents;
@end

@implementation ZincTask

@synthesize repo = _repo;
@synthesize suboperations = _suboperations;
@synthesize supertask = _supertask;
@synthesize myEvents = _myEvents;
@synthesize title = _title;
@synthesize finishedSuccessfully = _finishedSuccessfully;

- (id) initWithRepo:(ZincRepo*)repo
{
    self = [super init];
    if (self) {
        self.repo = repo;
        self.myEvents = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc 
{
    self.suboperations = nil;
    self.myEvents = nil;
    self.repo = nil;
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

- (NSString*) key
{
    NSAssert(NO, @"must override");
    return nil;
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
