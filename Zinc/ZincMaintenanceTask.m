//
//  ZincMaintenanceTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/18/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincMaintenanceTask.h"
#import "ZincTask+Private.h"
#import "ZincEvent.h"
#import "ZincTaskDescriptor.h"


@implementation ZincMaintenanceTask

+ (NSString *)action
{
    NSAssert(NO, @"method must be defined by subclass");
    return nil;
}

+ (ZincTaskDescriptor*) taskDescriptorForResource:(NSURL*)resource
{
    return [ZincTaskDescriptor taskDescriptorWithResource:resource action:[self action] method:[self taskMethod]];
}

- (void) main
{
    [self addEvent:[ZincMaintenanceBeginEvent maintenanceEventWithAction:[[self class] action]]];
    [self doMaintenance];
    [self addEvent:[ZincMaintenanceCompleteEvent maintenanceEventWithAction:[[self class] action]]];
}

- (void)doMaintenance
{
    NSAssert(NO, @"method must be defined by subclass");
}

@end
