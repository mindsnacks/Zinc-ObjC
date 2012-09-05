//
//  ZincTaskRef.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/29/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTaskRef.h"
#import "ZincTask.h"

@implementation ZincTaskRef

- (ZincTask*) getTask
{
    if ([self.dependencies count] > 0) {
        return [self.dependencies objectAtIndex:0];
    }
    return nil;
}

- (NSArray*) getAllErrors
{
    return [[self getTask] getAllErrors];
}

@end
