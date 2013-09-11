//
//  ZincProgress.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincProgress+Private.h"


float ZincProgressPercentageCalculate(id<ZincProgress> progress)
{
    long long max = [progress maxProgressValue];
    long long cur = [progress currentProgressValue];
    if (max > 0 && cur > 0) {
        return (float)cur / max;
    }
    return 0.0f;
}


@implementation ZincProgressItem

- (void) finish
{
    self.currentProgressValue = self.maxProgressValue;
    self.progressPercentage = 1.0f;
}

- (BOOL) isFinished
{
    return self.progressPercentage == 1.0f;
}

- (BOOL) updateCurrentProgressValue:(long long)currentProgressValue maxProgressValue:(long long)maxProgressValue
{
    BOOL progressValuesChanged = NO;

    if (self.currentProgressValue != currentProgressValue) {
        self.currentProgressValue = currentProgressValue;
        progressValuesChanged = YES;
    }

    if (self.maxProgressValue != maxProgressValue) {
        self.maxProgressValue = maxProgressValue;
        progressValuesChanged = YES;
    }

    if (progressValuesChanged) {
        self.progressPercentage = ZincProgressPercentageCalculate(self);
    }

    return progressValuesChanged;
}

- (BOOL) updateFromProgress:(id<ZincProgress>)progress
{
    return [self updateCurrentProgressValue:[progress currentProgressValue] maxProgressValue:[progress maxProgressValue]];
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@: %p currentProgressValue=%lld maxProgressValue=%lld progressPercentage=%f>", NSStringFromClass([self class]), self, self.currentProgressValue, self.maxProgressValue, self.progressPercentage];
}

@end
