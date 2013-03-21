//
//  ZincInternalTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 3/16/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincInternalTask.h"
#import "ZincTask+Private.h"

@implementation ZincInternalTask

+ (NSString *)action
{
    return [self taskMethod];
}

@end
