//
//  ZincBundleAvailabilityMonitorSpec.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/10/13.
//  Copyright 2013 MindSnacks. All rights reserved.
//

#import "ZincBundleAvailabilityMonitor+Private.h"

SPEC_BEGIN(ZincBundleAvailabilityMonitorSpec)

describe(@"ZincBundleAvailabilityMonitorItem", ^{

    __block ZincBundleAvailabilityMonitorItem* item;
    __block id monitor;
    NSString* const bundleID = @"com.mindsnacks.bundle1";

    context(@"newly created", ^{

        beforeEach(^{
            monitor = [ZincBundleAvailabilityMonitor nullMock];
            item = [[ZincBundleAvailabilityMonitorItem alloc] initWithMonitor:monitor bundleID:bundleID];
        });

        it(@"should have zero current progress", ^{
            [[theValue(item.currentProgressValue) should] equal:theValue(0)];
        });

        it(@"should have non-zero max progress", ^{
            [[theValue(item.maxProgressValue) should] beGreaterThan:theValue(0)];
        });
    });


});

SPEC_END
