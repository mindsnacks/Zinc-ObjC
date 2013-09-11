//
//  ZincProgressSpec.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/10/13.
//  Copyright 2013 MindSnacks. All rights reserved.
//

#import "ZincProgress+Private.h"

SPEC_BEGIN(ZincProgressSpec)

describe(@"ZincProgressItem", ^{

    __block  ZincProgressItem* item;

    dispatch_block_t checkExplicitlyFinished = ^{
        
        context(@"when explicitly finished", ^{

            beforeEach(^{
                [item finish];
            });

            it(@"should report finished", ^{
                [[theValue([item isFinished]) should] beTrue];
            });

            it(@"current progress and max progress should be equal", ^{
                [[theValue([item currentProgressValue]) should] equal:theValue([item maxProgressValue])];
            });
        });
    };

    beforeEach(^{
        item = [[ZincProgressItem alloc] init];
    });

    context(@"when newly created", ^{

        it(@"should not be finished", ^{
            [[theValue([item isFinished]) shouldNot] beTrue];
        });

        it(@"should have no progress percentage", ^{
            [[theValue([item progressPercentage]) should] equal:0.0 withDelta:0.0];
        });

        checkExplicitlyFinished();
    });

    context(@"when progress is updated but not complete", ^{

        long long curProgress = 10;
        long long maxProgress = 100;

        beforeEach(^{
            [item updateCurrentProgressValue:curProgress maxProgressValue:maxProgress];
        });

        it(@"should not be finished", ^{
            [[theValue([item isFinished]) shouldNot] beTrue];
        });

        it(@"should have the correct progress percentage", ^{
            [[theValue([item progressPercentage]) should] equal:0.1 withDelta:0.001];
        });

        checkExplicitlyFinished();
    });

    context(@"when progress is updated and complete", ^{

        long long curProgress = 100;
        long long maxProgress = 100;

        beforeEach(^{
            [item updateCurrentProgressValue:curProgress maxProgressValue:maxProgress];
        });

        it(@"should be finished", ^{
            [[theValue([item isFinished]) should] beTrue];
        });

        it(@"should have the correct progress percentage", ^{
            [[theValue([item progressPercentage]) should] equal:1.0 withDelta:0.0];
        });

        checkExplicitlyFinished();
    });
});

SPEC_END
