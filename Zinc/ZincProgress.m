//
//  ZincProgress.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincProgress+Private.h"
#import "ZincInternals.h"


const long long ZincProgressNotYetDetermined = -(LONG_LONG_MAX);

float ZincProgressPercentageCalculate(id<ZincProgress> progress)
{
    long long max = [progress maxProgressValue];
    long long cur = [progress currentProgressValue];
    if (max > 0 && cur > 0) {
        return (float)cur / max;
    }
    return 0.0f;
}

id<ZincProgress> ZincAggregatedProgressCalculate(NSArray* items)
{
    ZincProgressItem* total = [[ZincProgressItem alloc] init];
    long long totalCurrentProgress = 0;
    long long totalMaxProgress = 0;
    BOOL anyUndetermined = NO;
    
    for (id<ZincProgress> item in items) {

        ZINC_DEBUG_LOG(@"%@: %lld %lld", item, [item currentProgressValue], [item maxProgressValue]);

        if (([item currentProgressValue] == ZincProgressNotYetDetermined) ||
            ([item maxProgressValue] == ZincProgressNotYetDetermined)) {
            anyUndetermined = YES;
            break;
        } else {
            totalCurrentProgress += [item currentProgressValue];
            totalMaxProgress += [item maxProgressValue];
        }
    }

    if (!anyUndetermined) {
        [total updateCurrentProgressValue:totalCurrentProgress maxProgressValue:totalMaxProgress];
    }

    ZINC_DEBUG_LOG(@"---------------- %f ", total.progressPercentage);
    return total;
}

@implementation ZincProgressItem

- (id)init
{
    self = [super init];
    if (self) {
        _currentProgressValue = ZincProgressNotYetDetermined;
        _maxProgressValue = ZincProgressNotYetDetermined;
    }
    return self;
}

- (void) finish
{
    self.currentProgressValue = self.maxProgressValue;
    self.progressPercentage = 1.0f;
}

- (void) setCurrentProgressValue:(long long)currentProgressValue
{
    _currentProgressValue = currentProgressValue;
    [self updateFromProgress:self];
}

- (void) setMaxProgressValue:(long long)maxProgressValue
{
    _maxProgressValue = maxProgressValue;
    [self updateFromProgress:self];
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
    NSParameterAssert(progress);
    return [self updateCurrentProgressValue:[progress currentProgressValue] maxProgressValue:[progress maxProgressValue]];
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@: %p currentProgressValue=%lld maxProgressValue=%lld progressPercentage=%f>", NSStringFromClass([self class]), self, self.currentProgressValue, self.maxProgressValue, self.progressPercentage];
}

@end
