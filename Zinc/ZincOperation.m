//
//  ZincOperation.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperation.h"

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

- (NSInteger) currentProgressValue
{
    return [[self.zincDependencies valueForKeyPath:@"@sum.currentProgressValue"] integerValue];
}

- (NSInteger) maxProgressValue
{
    return [[self.zincDependencies valueForKeyPath:@"@sum.maxProgressValue"] integerValue];
}

- (double) progress
{
    NSInteger max = [self maxProgressValue];
    if (max > 0) {
        return (double)self.currentProgressValue / max;
    }
    return 0;
}

- (void) cancel
{
    @synchronized(self) {
        [super cancel];
        [self.dependencies makeObjectsPerformSelector:@selector(cancel)];
    }
}


@end
