//
//  ZincCompleteInitializationTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/21/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincCompleteInitializationTask.h"

#import "ZincRepo+Private.h"

@implementation ZincCompleteInitializationTask

+ (NSString *)action
{
    return @"CompleteInitialization";
}

- (void) doMaintenance
{
    NSArray* allErrors = [self allErrors];
    if ([allErrors count] == 0) {
        [self.repo completeInitialization];
    }
}

@end
