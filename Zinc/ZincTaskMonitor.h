//
//  ZincTaskMonitor.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincCompletableActivityMonitor.h"

@class ZincTaskRef;

/**
 A ZincTaskMonitor monitors a single task for progress and completion. This is part of the Zinc-ObjC public API, and is encouraged to be used in client code.
 */
@interface ZincTaskMonitor : ZincCompletableActivityMonitor

/**
 Create a `ZincTaskMonitor`.

 Designated initializer.
 
 @param taskRefs an `NSArray` containing `ZincTaskRef`s
 */
- (id) initWithTaskRefs:(NSArray*)taskRefs;

/**
 Create a `ZincTaskMonitor.
 
 Convenience method.
 
 @param taskRef a `ZincTaskRef`
 */
+ (instancetype) taskMonitorForTaskRef:(ZincTaskRef*)taskRef;

/**
 The taskRef the monitor was initialized with
 */
@property (nonatomic, strong, readonly) NSArray* taskRefs;

/**
 Return all errors encountered so far.
 @return An array of errors
 */
- (NSArray*) allErrors;

@end
