//
//  ZincCompletableActivityMonitorSpec.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/10/13.
//  Copyright 2013 MindSnacks. All rights reserved.
//

#import "ZincCompletableActivityMonitor.h"
#import "ZincActivityMonitor+Private.h"
#import "ZincProgress+Private.h"

SPEC_BEGIN(ZincCompletableActivityMonitorSpec)

describe(@"ZincCompletableActivityMonitor", ^{

    __block ZincMockFactory* mockFactory;
    __block ZincCompletableActivityMonitor* monitor;

    beforeEach(^{
        mockFactory = [[ZincMockFactory alloc] init];
        monitor = [[ZincCompletableActivityMonitor alloc] init];
        monitor.refreshInterval = 0;
    });

    context(@"has a single item", ^{

        __block ZincActivityItem* item;

        beforeEach(^{
            item = [[ZincActivityItem alloc] initWithActivityMonitor:monitor];
            [monitor addItem:item];
        });

        context(@"the item is complete", ^{

            const long long itemProgressValue = 50;

            beforeEach(^{
                [item stub:@selector(isFinished) andReturn:theValue(YES)];
                [item stub:@selector(currentProgressValue) andReturn:theValue(itemProgressValue)];
                [item stub:@selector(maxProgressValue) andReturn:theValue(itemProgressValue)];
                [item stub:@selector(progressPercentage) andReturn:theValue(1.0f)];
            });

            it(@"calls completion block", ^{
                __block BOOL blockCalled = NO;
                monitor.completionBlock = ^{
                    blockCalled = YES;
                };

                [monitor update];

                [[expectFutureValue(theValue(blockCalled)) shouldEventually] beTrue];
            });
        });
    });

    context(@"has multiple items", ^{

        __block ZincActivityItem* item1;
        __block ZincActivityItem* item2;

        beforeEach(^{
            item1 = [[ZincActivityItem alloc] initWithActivityMonitor:monitor];
            item2 = [[ZincActivityItem alloc] initWithActivityMonitor:monitor];
            [monitor addItem:item1];
            [monitor addItem:item2];
        });

        context(@"items have progress but not finished", ^{

            const long long item1CurrentProgressValue = 5;
            const long long item1MaxProgressValue = 10;
            const long long item2CurrentProgressValue = 10;
            const long long item2MaxProgressValue = 100;
            const long long overallCurrentProgressValue = item1CurrentProgressValue + item2CurrentProgressValue;
            const long long overallMaxProgressValue = item1MaxProgressValue + item2MaxProgressValue;
            const float overallProgressPercentage = (float)overallCurrentProgressValue / overallMaxProgressValue;

            beforeEach(^{
                item1.subject = [mockFactory mockActivitySubjectWithCurrentProgressValue:item1CurrentProgressValue maxProgressValue:item1MaxProgressValue isFinished:NO];
                item2.subject = [mockFactory mockActivitySubjectWithCurrentProgressValue:item2CurrentProgressValue maxProgressValue:item2MaxProgressValue isFinished:NO];
            });

            it(@"sets overall progress when updated", ^{
                [monitor update];
                [[theValue(monitor.progress.currentProgressValue) should] equal:theValue(overallCurrentProgressValue)];
                [[theValue(monitor.progress.maxProgressValue) should] equal:theValue(overallMaxProgressValue)];
                [[theValue(monitor.progress.progressPercentage) should] equal:overallProgressPercentage withDelta:0.001];
            });

            it(@"calls the progress block", ^{
                __block BOOL progressBlockCalled = NO;
                monitor.progressBlock = ^(id context, long long currentProgressValue, long long maxProgressValue, float progressPercentage) {
                    if (context == monitor) {
                        progressBlockCalled = YES;
                    }
                };

                [monitor update];

                [[expectFutureValue(theValue(progressBlockCalled)) shouldEventually] beTrue];
            });
        });

        context(@"one item has progress not yet determined", ^{

            const long long item1CurrentProgressValue = ZincProgressNotYetDetermined;
            const long long item1MaxProgressValue = 10;
            const long long item2CurrentProgressValue = 10;
            const long long item2MaxProgressValue = 100;

            beforeEach(^{
                item1.subject = [mockFactory mockActivitySubjectWithCurrentProgressValue:item1CurrentProgressValue maxProgressValue:item1MaxProgressValue isFinished:NO];
                item2.subject = [mockFactory mockActivitySubjectWithCurrentProgressValue:item2CurrentProgressValue maxProgressValue:item2MaxProgressValue isFinished:NO];
            });

            it(@"should have undetermind overall progress", ^{
                [monitor update];
                [[theValue([monitor.progress currentProgressValue]) should] equal:theValue(ZincProgressNotYetDetermined)];
                [[theValue([monitor.progress maxProgressValue]) should] equal:theValue(ZincProgressNotYetDetermined)];
            });
        });
    });
});

SPEC_END
