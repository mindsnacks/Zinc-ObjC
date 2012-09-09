//
//  ZincTaskMonitor.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincActivityMonitor.h"

typedef void (^ZincTaskMonitorProgressBlock)(long long currentProgress, long long totalProgress, float percent);

@class ZincTaskRef;

@interface ZincTaskMonitor : ZincActivityMonitor

- (id) initWithTaskRef:(ZincTaskRef*)taskRef;
+ (ZincTaskMonitor*) taskMonitorForTaskRef:(ZincTaskRef*)taskRef;

@property (nonatomic, copy) ZincTaskMonitorProgressBlock progressBlock;
@property (nonatomic, copy) ZincCompletionBlock completionBlock;

/**
 @discussion Is Key-Value Observable
 */
@property (nonatomic, readonly) float progress;

/**
 @discussion Is Key-Value Observable
 */
@property (atomic, assign) long long currentProgressValue;

/**
 @discussion Is Key-Value Observable
 */
@property (atomic, assign) long long maxProgressValue;

@end
