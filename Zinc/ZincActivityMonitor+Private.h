//
//  ZincActivityMonitor+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//


#import "ZincActivityMonitor.h"

@interface ZincActivityMonitor ()

#pragma mark Subclasses

- (void) addItem:(ZincActivityItem*)item;
- (void) removeItem:(ZincActivityItem*)item;

- (void) monitoringDidStart;
- (void) monitoringDidStop;

- (void) update;

- (NSArray*) finishedItems;

@end


@interface ZincActivityItem ()

- (id) initWithActivityMonitor:(ZincActivityMonitor*)monitor subject:(id<ZincProgress>)subject;

- (id) initWithActivityMonitor:(ZincActivityMonitor*)monitor;

@property (nonatomic, readwrite, strong) id<ZincProgress> subject;

- (void) update;

@end