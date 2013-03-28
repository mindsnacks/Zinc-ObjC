//
//  ZincOperation.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperation.h"
#import "NSOperation+Zinc.h"

double const kZincOperationInitialDefaultThreadPriority = 0.5;

@implementation ZincOperation

double _defaultThreadPriority = kZincOperationInitialDefaultThreadPriority;

+ (void)setDefaultThreadPriority:(double)defaultThreadPriority
{
    @synchronized(self) {
        _defaultThreadPriority = defaultThreadPriority;
    }
}

+ (double)defaultThreadPriority
{
    return _defaultThreadPriority;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.threadPriority = [[self class] defaultThreadPriority];
    }
    return self;
}

- (NSArray*) zincDependencies
{
    return [self.dependencies filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^(id obj, NSDictionary* bindings) {
        return [obj isKindOfClass:[ZincOperation class]];
    }]];
}

- (long long) currentProgressValue
{
    return [[self.zincDependencies valueForKeyPath:@"@sum.currentProgressValue"] longLongValue] + ([self isFinished] ? 1 : 0);
}

- (long long) maxProgressValue
{
    return [[self.zincDependencies valueForKeyPath:@"@sum.maxProgressValue"] longLongValue] + 1;
}

- (float) progress
{
    return ZincProgressCalculate(self);
}

- (void)addDependency:(NSOperation *)op
{
    NSAssert(![[op zinc_allDependencies] containsObject:self], @"attempt to add circular dependency");
    [super addDependency:op];
}

@end
