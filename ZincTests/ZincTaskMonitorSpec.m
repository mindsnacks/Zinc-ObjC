//
//  ZincTaskMonitorSpec.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/10/13.
//  Copyright 2013 MindSnacks. All rights reserved.
//

#import "ZincTaskMonitor.h"
#import "ZincActivityMonitor+Private.h"
#import "ZincTaskRef.h"

SPEC_BEGIN(ZincTaskMonitorSpec)

describe(@"ZincTaskMonitor", ^{

    context(@"has a single task", ^{

        __block ZincTaskRefDummy* taskRef;
        __block ZincTaskMonitor* monitor;

        beforeEach(^{
            taskRef = [[ZincTaskRefDummy alloc] init];
            taskRef.isValid = YES;
            taskRef.isFinished = NO;

            monitor = [[ZincTaskMonitor alloc] initWithTaskRefs:@[taskRef]];
            monitor.refreshInterval = 0;
        });

        it(@"creates an activity item", ^{
            [[[monitor items] should] haveCountOf:1];
            ZincActivityItem* item = [[monitor items] objectAtIndex:0];
            [[(NSObject*)item.subject should] beIdenticalTo:taskRef];
        });

        it(@"finishes if the tasks finishes after monitoring starts", ^{
            [monitor startMonitoring];
            taskRef.isFinished = YES;
            [monitor update];
            [[theValue([monitor.progress isFinished]) should] beTrue];
        });

        it(@"finishes if the tasks finishes before monitoring starts", ^{
            taskRef.isFinished = YES;
            [monitor startMonitoring];
            [[theValue([monitor.progress isFinished]) should] beTrue];
        });
    });

});


SPEC_END
