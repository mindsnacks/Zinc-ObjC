//
//  ZincTaskMonitor.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincActivityMonitor.h"
#import "ZincProgress.h"

@class ZincTaskRef;

/**
 A ZincTaskMonitor monitors a single task for progress and completion. This is part of the Zinc-ObjC public API, and is encouraged to be used in client code.
 */
@interface ZincTaskMonitor : ZincActivityMonitor <ZincObservableProgress>

/**
 Create a `ZincTaskMonitor`.
 
 Designated initializer.
 */
- (id) initWithTaskRef:(ZincTaskRef*)taskRef;

/**
 Create a `ZincTaskMonitor.
 
 Convenience method.
 */
+ (instancetype) taskMonitorForTaskRef:(ZincTaskRef*)taskRef;

/**
 The taskRef the monitor was initialized with
 */
@property (nonatomic, strong, readonly) ZincTaskRef* taskRef;

/**
 @discussion Similar to NSOperation, the exact execution context for your completion block is not guaranteed but is typically a secondary thread.
 */
@property (nonatomic, copy) ZincCompletionBlock completionBlock;

@end
