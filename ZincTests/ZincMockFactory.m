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
#import "ZincProgress+Private.h"
#import "ZincActivityMonitor+Private.h"

@implementation ZincMockFactory

- (id) mockOperation
{
    id progress = [ZincProgressItem mock];
    id operation = [ZincOperation mock];
    [operation stub:@selector(progress) andReturn:progress];
    return operation;
}


- (id) mockBundleCloneTaskForBundleID:(NSString*)bundleID version:(ZincVersion)version
{
    NSURL* resource = [NSURL zincResourceForBundleWithID:bundleID version:version];
    ZincTaskDescriptor* taskDescriptor = [[ZincTaskDescriptor alloc] initWithResource:resource action:ZincTaskActionUpdate method:NSStringFromClass([ZincTask class])];
    id task = [ZincTask mock];
    [task stub:@selector(taskDescriptor) andReturn:taskDescriptor];
    [task stub:@selector(resource) andReturn:resource];
    [task stub:@selector(isFinished) andReturn:theValue(NO)];

    id progress = [ZincProgressItem mock];
    [progress stub:@selector(currentProgressValue) andReturn:theValue(0)];
    [progress stub:@selector(maxProgressValue) andReturn:theValue(0)];
    [task stub:@selector(progress) andReturn:progress];

    return task;
}

- (id) mockActivitySubjectWithCurrentProgressValue:(long long)currentProgress
                                  maxProgressValue:(long long)maxProgressValue
                                        isFinished:(BOOL)isFinished
{
    ZincProgressItem *progress = [[ZincProgressItem alloc] init];
    [progress updateCurrentProgressValue:currentProgress maxProgressValue:maxProgressValue];
    id subject = [KWMock mockForProtocol:@protocol(ZincActivitySubject)];
    [subject stub:@selector(progress) andReturn:progress];
    [subject stub:@selector(isFinished) andReturn:theValue(isFinished)];
    return subject;
}


@end
