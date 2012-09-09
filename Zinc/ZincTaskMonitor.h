//
//  ZincTaskMonitor.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincGlobals.h"

static NSTimeInterval const kZincTaskMonitorDefaultRefreshInterval = 0.5;

typedef void (^ZincTaskMonitorProgressBlock)(long long currentProgress, long long totalProgress, float percent);

@class ZincTaskRef;

@interface ZincTaskMonitor : NSObject

- (id) initWithTaskRef:(ZincTaskRef*)taskRef;
+ (ZincTaskMonitor*) taskMonitorForTaskRef:(ZincTaskRef*)taskRef;

@property (nonatomic, assign) NSTimeInterval refreshInterval;
@property (nonatomic, copy) ZincTaskMonitorProgressBlock progressBlock;
@property (nonatomic, copy) ZincCompletionBlock completionBlock;

- (void) startMonitoring;
- (void) stopMonitoring;
@property (nonatomic, readonly, assign) BOOL isMonitoring;

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
