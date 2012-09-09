//
//  ZincTaskRef2.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/3/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperation.h"

@class ZincTask;

typedef void (^ZincTaskProgressBlock)(long long currentProgress, long long totalProgress, float percent);


@interface ZincTaskRef2 : ZincOperation

@property (nonatomic, readonly) float progress;

/* all events including events from subtasks */
- (NSArray*) events;

/* all errors that occurred including errors from subtasks */
- (NSArray*) errors;

- (void) setProgressBlock:(ZincTaskProgressBlock)block;



#pragma mark private

- (id)initWithTask:(ZincTask*) task;

@end



