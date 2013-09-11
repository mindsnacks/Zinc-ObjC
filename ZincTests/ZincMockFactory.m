//
//  ZincMockFactory.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/10/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincMockFactory.h"

#import "ZincResource.h"
#import "ZincTaskDescriptor.h"
#import "ZincTask.h"
#import "ZincTaskActions.h"

@implementation ZincMockFactory

- (id) mockBundleCloneTaskForBundleID:(NSString*)bundleID version:(ZincVersion)version
{
    NSURL* resource = [NSURL zincResourceForBundleWithID:bundleID version:version];
    ZincTaskDescriptor* taskDescriptor = [[ZincTaskDescriptor alloc] initWithResource:resource action:ZincTaskActionUpdate method:NSStringFromClass([ZincTask class])];
    id task = [ZincTask mock];
    [task stub:@selector(taskDescriptor) andReturn:taskDescriptor];
    [task stub:@selector(resource) andReturn:resource];
    [task stub:@selector(isFinished) andReturn:theValue(NO)];
    [task stub:@selector(currentProgressValue) andReturn:theValue(0)];
    [task stub:@selector(maxProgressValue) andReturn:theValue(0)];
    return task;
}

@end
