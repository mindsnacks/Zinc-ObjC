//
//  ZincOperationQueueGroupSpec.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/16/13.
//  Copyright 2013 MindSnacks. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "ZincOperationQueueGroup+Private.h"

#define SYNTHESIZE_DUMMY_OP(cls)\
@interface cls : NSOperation \
@end \
@implementation cls \
@end

SYNTHESIZE_DUMMY_OP(ZincDummyOp);
SYNTHESIZE_DUMMY_OP(ZincDummyBarrierOp);


SPEC_BEGIN(ZincOperationQueueGroupSpec)

describe(@"ZincOperationQueueGroup", ^{

    __block ZincOperationQueueGroup* queueGroup = nil;

    beforeEach(^{
        queueGroup = [[ZincOperationQueueGroup alloc] init];
    });

    context(@"newly created", ^{
        specify(^{
            [[theValue([queueGroup isSuspended]) should] beTrue];
        });
    });

    context(@"max concurrent operation count is set", ^{

        NSUInteger maxCount = 3;

        beforeEach(^{
            [queueGroup setMaxConcurrentOperationCount:maxCount forClass:[ZincDummyOp class]];
        });
    });
    

    context(@"dependency calculation", ^{

        __block id barrierOp;
        __block id regularOp1;

        beforeEach(^{

            barrierOp = [[ZincDummyBarrierOp alloc] init];
            regularOp1 = [[ZincDummyOp alloc] init];

            [queueGroup setIsBarrierOperationForClass:[ZincDummyBarrierOp class]];
        });

        context(@"barrier op is added", ^{

            beforeEach(^{
                [queueGroup addOperation:barrierOp];
            });

            specify(^{
                [[[queueGroup getAllBarrierOperations] should] haveCountOf:1];
            });

            specify(^{
                [[[queueGroup getAllBarrierOperations] should] contain:barrierOp];
            });
        });
    });
});

SPEC_END
