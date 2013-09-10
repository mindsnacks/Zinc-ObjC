//
//  ZincActivitityMonitorSpec.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/10/13.
//  Copyright 2013 MindSnacks. All rights reserved.
//

#import "ZincActivityMonitor+Private.h"
#import "ZincProgress+Private.h"
#import "ZincOperation.h"

SPEC_BEGIN(ZincActivitityMonitorSpec)

describe(@"ZincActivityItem", ^{

    __block ZincActivityItem* item;
    __block id monitor;
    
    beforeEach(^{
        monitor = [ZincActivityMonitor mock];
        [monitor stub:@selector(progressBlock) andReturn:nil];

        item = [[ZincActivityItem alloc] initWithActivityMonitor:monitor];
    });
    
    it(@"sets progress correctly", ^{
        item.progressPercentage = 0.5;
        [[theValue(item.progressPercentage) should] equal:0.5 withDelta:0.001];
    });

    context(@"has an operation", ^{

        __block id operation;

        beforeEach(^{
            operation = [ZincOperation mock];
            item.operation = operation;
        });

        context(@"operation is not finished", ^{

            const long long currentProgressValue = 10;
            const long long maxProgressValue = 100;

            beforeEach(^{
                [operation stub:@selector(isFinished) andReturn:theValue(NO)];
                [operation stub:@selector(currentProgressValue) andReturn:theValue(currentProgressValue)];
                [operation stub:@selector(maxProgressValue) andReturn:theValue(maxProgressValue)];
            });

            it(@"has the right progress when updated", ^{
                [item update];
                [[theValue(item.currentProgressValue) should] equal:theValue(currentProgressValue)];
                [[theValue(item.maxProgressValue) should] equal:theValue(maxProgressValue)];
            });
        });

        context(@"operation is finished", ^{

            beforeEach(^{
                [operation stub:@selector(isFinished) andReturn:theValue(YES)];
            });

            it(@"item is finished when updated", ^{
                [item update];
                [[theValue([item isFinished]) should] beTrue];
            });
        });
    });

    context(@"monitor has progress block", ^{

        __block id blockContext;
        __block long long blockCurrentProgress;
        __block long long blockTotalProgress;
        __block float blockPercent;

        beforeEach(^{

            blockContext = nil;
            blockCurrentProgress = 0;
            blockTotalProgress = 0;
            blockPercent = 0;

            [monitor stub:@selector(progressBlock)
                andReturn:[^(id context, long long currentProgress, long long totalProgress, float percent) {
                    blockContext = context;
                    blockCurrentProgress = currentProgress;
                    blockTotalProgress = totalProgress;
                    blockPercent = percent;
            } copy]];
        });

        it(@"calls the progress block correctly", ^{

            long long currentProgress = 10;
            long long maxProgress = 100;

            [item updateCurrentProgressValue:currentProgress maxProgressValue:maxProgress];

            [[expectFutureValue(blockContext) shouldEventually] beIdenticalTo:item];
            [[expectFutureValue(theValue(blockCurrentProgress)) shouldEventually] equal:theValue(currentProgress)];
            [[expectFutureValue(theValue(blockTotalProgress)) shouldEventually] equal:theValue(maxProgress)];
            [[expectFutureValue(theValue(blockPercent)) shouldEventually] equal:(double)currentProgress/maxProgress withDelta:0.001];
        });
    });
});

describe(@"ZincActivitityMonitor", ^{

   __block ZincActivityMonitor* monitor;

    beforeEach(^{
        monitor = [[ZincActivityMonitor alloc] init];
        monitor.refreshInterval = 0;
    });

    context(@"newly created", ^{

        it(@"should not be monitoring", ^{
            [[theValue(monitor.isMonitoring) should] beFalse];
        });

    });

    context(@"has a single item", ^{

        __block ZincActivityItem* item;

        beforeEach(^{
            item = [[ZincActivityItem alloc] initWithActivityMonitor:monitor];
            [monitor stub:@selector(items) andReturn:@[item]];
        });

        it(@"has the correct items", ^{
            [[[monitor items] should] haveCountOf:1];
            [[[monitor items] should] contain:item];
        });

        it(@"updates it's items when updated", ^{
            [[item should] receive:@selector(update)];
            [monitor update];
        });

        it(@"posts a notification when updated", ^{
            id mock = [OCMockObject observerMock];
            [[NSNotificationCenter defaultCenter] addMockObserver:mock
                                                             name:ZincActivityMonitorRefreshedNotification
                                                           object:nil];
            [[mock expect] notificationWithName:ZincActivityMonitorRefreshedNotification object:[OCMArg any]];
            [monitor update];
            [mock verify];
            [[NSNotificationCenter defaultCenter] removeObserver:mock];
        });

        it(@"should update after refresh interval", ^{

            // set a finished operation on the item
            __block id operation = [ZincOperation mock];
            [operation stub:@selector(isFinished) andReturn:theValue(YES)];
            item.operation = operation;

            // make sure it's not finished
            [[theValue([item isFinished]) should] beFalse];

            // start monitoring
            const NSTimeInterval refreshInterval = 0.5;
            monitor.refreshInterval = refreshInterval;
            [monitor startMonitoring];

            // and expect it will be finished
            [[expectFutureValue(theValue([item isFinished])) shouldEventuallyBeforeTimingOutAfter(refreshInterval*2)] beTrue];
        });
    });
});

SPEC_END
