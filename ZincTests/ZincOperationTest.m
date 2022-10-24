//
//  ZincOperationTest.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 5/1/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincOperation.h"


@interface ZincOperationTest : XCTestCase
@end


@implementation ZincOperationTest

- (void) testAddDependencyOK
{
    ZincOperation* op1 = [[[ZincOperation alloc] init] autorelease];
    ZincOperation* op2 = [[[ZincOperation alloc] init] autorelease];
    ZincOperation* op3 = [[[ZincOperation alloc] init] autorelease];

    XCTAssertNoThrow([op1 addDependency:op2], @"adding dep should not throw");
    XCTAssertNoThrow([op1 addDependency:op3], @"adding dep should not throw");
    XCTAssertNoThrow([op2 addDependency:op3], @"adding dep should not throw");

}

- (void) testAddDependencyCircularDirect
{
    ZincOperation* op1 = [[[ZincOperation alloc] init] autorelease];
    ZincOperation* op2 = [[[ZincOperation alloc] init] autorelease];

    XCTAssertNoThrow([op1 addDependency:op2], @"adding a single dep should not throw");
    XCTAssertThrows([op2 addDependency:op1], @"should throw");
}

- (void) testAddDependencyCircularIndirect
{
    ZincOperation* op1 = [[[ZincOperation alloc] init] autorelease];
    ZincOperation* op2 = [[[ZincOperation alloc] init] autorelease];
    ZincOperation* op3 = [[[ZincOperation alloc] init] autorelease];

    XCTAssertNoThrow([op1 addDependency:op2], @"adding dep should not throw");
    XCTAssertNoThrow([op2 addDependency:op3], @"adding dep should not throw");
    XCTAssertThrows([op3 addDependency:op1], @"should throw");
}

@end
