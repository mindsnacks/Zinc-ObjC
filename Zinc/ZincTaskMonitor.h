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
 @discussion A ZincTaskMonitor monitors a single task for progress and completion. This is part of the Zinc-ObjC public API, and is encouraged to be used in client code.
 */
@interface ZincTaskMonitor : ZincActivityMonitor <ZincObservableProgress>

- (id) initWithTaskRef:(ZincTaskRef*)taskRef;
+ (ZincTaskMonitor*) taskMonitorForTaskRef:(ZincTaskRef*)taskRef;

/**
 @discussion taskRef the monitor was initialized with
 */
@property (nonatomic, retain, readonly) ZincTaskRef* taskRef;

/**
 @discussion Similar to NSOperation, the exact execution context for your completion block is not guaranteed but is typically a secondary thread.
 */
@property (nonatomic, copy) ZincCompletionBlock completionBlock;

@end
