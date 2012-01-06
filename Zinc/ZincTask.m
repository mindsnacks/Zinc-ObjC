//
//  ZincTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/5/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"

@interface ZincTask ()
//@property (nonatomic, retain, readwrite) NSMutableArray* mySubtasks;
@property (nonatomic, retain, readwrite) NSMutableArray* myEvents;
@end

@implementation ZincTask

@synthesize myEvents = _myEvents;
//@synthesize mySubtasks = _mySubtasks;

- (void)dealloc 
{
    self.myEvents = nil;
//    self.mySubtasks = nil;
    [super dealloc];
}

//- (NSArray*) subtasks
//{
//    return [NSArray arrayWithArray:self.mySubtasks];
//}

- (NSArray*) events
{
    return [NSArray arrayWithArray:self.myEvents];
}

@end
