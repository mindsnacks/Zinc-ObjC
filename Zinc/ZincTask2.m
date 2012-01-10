//
//  ZincTask2.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask2.h"
#import "ZincClient.h"
#import "ZincClient+Private.h"

@interface ZincTask2 ()
@property (nonatomic, assign, readwrite) ZincClient* client;
@property (nonatomic, retain) NSMutableArray* myEvents;
@end

@implementation ZincTask2

@synthesize client = _client;
@synthesize suboperations = _suboperations;
@synthesize supertask = _supertask;
@synthesize myEvents = _myEvents;
@synthesize title = _title;
@synthesize finishedSuccessfully = _finishedSuccessfully;

- (id) initWithClient:(ZincClient*)client
{
    self = [super init];
    if (self) {
        self.client = client;
        self.myEvents = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc 
{
    self.suboperations = nil;
    self.myEvents = nil;
    self.client = nil;
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
        
        if ([operation isKindOfClass:[ZincTask2 class]]) {
            ZincTask2* task = (ZincTask2*)operation;
            task.supertask = self;
        }
        
        [self.suboperations addObject:operation];
        [self.client addOperation:operation];
    }
}

- (NSArray*) subtasks
{
    return [self.suboperations filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^(id obj, NSDictionary* bindings) {
        return [obj isKindOfClass:[ZincTask2 class]];
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
