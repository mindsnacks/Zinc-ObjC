//
//  ZincActivityMonitor+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//


#import "ZincActivityMonitor.h"

@class ZincTask;

@interface ZincActivityMonitor ()

- (void) monitoringDidStart;
- (void) monitoringDidStop;

- (void) update;

@end


@interface ZincActivityItem ()

- (id) initWithActivityMonitor:(ZincActivityMonitor*)monitor;

@property (nonatomic, readwrite, retain) ZincTask* task;
@property (nonatomic, assign, readwrite) long long currentProgressValue;
@property (nonatomic, assign, readwrite) long long maxProgressValue;
@property (nonatomic, assign, readwrite) float progress;

- (void) update;
- (void) finish;

@end