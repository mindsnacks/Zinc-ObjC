//
//  ZincTaskMonitor.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincActivityMonitor.h"
#import "ZincProgress.h"

typedef void (^ZincTaskMonitorProgressBlock)(long long currentProgress, long long totalProgress, float percent);

@class ZincTaskRef;

@interface ZincTaskMonitor : ZincActivityMonitor <ZincObservableProgress>

- (id) initWithTaskRef:(ZincTaskRef*)taskRef;
+ (ZincTaskMonitor*) taskMonitorForTaskRef:(ZincTaskRef*)taskRef;

@property (nonatomic, copy) ZincTaskMonitorProgressBlock progressBlock;
@property (nonatomic, copy) ZincCompletionBlock completionBlock;

@end
