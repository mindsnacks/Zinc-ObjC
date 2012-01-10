//
//  ZincTaskOperation.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTaskOperation.h"
#import "ZincTask.h"

@interface ZincTaskOperation ()
@property (nonatomic, retain, readwrite) ZincTask* task;
@property (nonatomic, retain) NSMutableSet* suboperations;
@end

@implementation ZincTaskOperation

@synthesize task = _task;
@synthesize suboperations = _suboperations;

- (id) initWithTask:(ZincTask*)task;
{
    self = [super init];
    if (self) {
        self.task = task;
        self.suboperations = [NSMutableSet set];
    }
    return self;
}

- (void)dealloc
{
    self.task = nil;
    self.suboperations = nil;
    [super dealloc];
}

- (void) addSuboperations:(NSArray*)operations
{
    [self.suboperations addObjectsFromArray:operations];
    for (NSOperation* op in operations) {
        //[self.dispatch addOperation:operation];
    }
}

- (void)cancel
{    
    [super cancel];

    [self.suboperations makeObjectsPerformSelector:@selector(cancel)];
}

@end
