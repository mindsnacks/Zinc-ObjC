//
//  ZincCompletableActivityMonitor.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/9/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincCompletableActivityMonitor.h"
#import "ZincActivityMonitor+Private.h"
#import "ZincProgress+Private.h"


@implementation ZincCompletableActivityMonitor

- (id)init
{
    self = [super init];
    if (self) {
        _progress = [[ZincProgressItem alloc] init];
    }
    return self;
}

- (void) callProgressBlock
{
    if (self.progressBlock != nil) {
        self.progressBlock(self, self.progress.currentProgressValue, self.progress.maxProgressValue, self.progress.progressPercentage);
    }
}

- (void) callCompletionBlock
{
    if (self.completionBlock != nil) {
        self.completionBlock();
        self.completionBlock = nil;
    }
}

- (void) complete
{
    [self.progress finish];
    [self callCompletionBlock];
    [self stopMonitoring];
}

- (void) itemsDidUpdate
{
    id<ZincProgress> newProgress = ZincAggregatedProgressCalculate([self items]);
    if ([self.progress updateFromProgress:newProgress]) {
        [self callProgressBlock];
    }

    const BOOL shouldComplete = [[self items] count] == [[self finishedItems] count];
    if (shouldComplete) {
        [self complete];
    }
}

@end

