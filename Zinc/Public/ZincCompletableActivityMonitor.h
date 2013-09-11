//
//  ZincCompletableActivityMonitor.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/9/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincActivityMonitor.h"
#import "ZincProgress.h"

@interface ZincCompletableActivityMonitor : ZincActivityMonitor

@property (nonatomic, readonly, strong) ZincProgressItem* progress;

/**
 Similar to NSOperation, the exact execution context for your completion block 
 is not guaranteed but is typically a secondary thread.
 */
@property (nonatomic, copy) dispatch_block_t completionBlock;

@end
