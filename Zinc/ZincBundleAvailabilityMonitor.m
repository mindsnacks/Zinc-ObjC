//
//  ZincBundleCloneMonitor.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleAvailabilityMonitor.h"
#import "ZincRepo.h"
#import "ZincTask.h"
#import "ZincTaskDescriptor.h"
#import "ZincResource.h"
#import "ZincTaskActions.h"

@implementation ZincBundleAvailabilityMonitor

- (id)initWithRepo:(ZincRepo*)repo bundleIDs:(NSArray*)bundleIDs
{
    NSPredicate* pred = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        
        ZincTask* task = (ZincTask*)evaluatedObject;
        ZincTaskDescriptor* taskDesc = task.taskDescriptor;
        NSURL* resource = taskDesc.resource;
        
        if (![resource isZincBundleResource]) return NO;
        if (![taskDesc.action isEqualToString:ZincTaskActionUpdate]) return NO;
        
        NSString* taskBundleID = [resource zincBundleId];
        if ([bundleIDs containsObject:taskBundleID]) return NO;
        
        if ([repo stateForBundleWithId:taskBundleID] == ZincBundleStateAvailable) return NO;
        
        return YES;
    }];
    
    return [self initWithRepo:repo taskPredicate:pred];
}

@end
