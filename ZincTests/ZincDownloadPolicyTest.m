//
//  ZincDownloadPolicyTest.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/21/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincDownloadPolicy.h"


@interface ZincDownloadPolicyTest : XCTestCase
@end


@implementation ZincDownloadPolicyTest

- (void) testThatConnectionTypeIsNotSetForLesserPriorityIsCorrectWhenSetForPriority
{
    ZincDownloadPolicy* policy = [[[ZincDownloadPolicy alloc] init] autorelease];
    policy.defaultRequiredConnectionType = ZincConnectionTypeWiFiOnly;
    
    [policy setRequiredConnectionType:ZincConnectionTypeAny forPrioritiesGreaterThanOrEqualToPriority:NSOperationQueuePriorityHigh];
    
    ZincConnectionType resolvedConnectionType = [policy requiredConnectionTypeForPriority:NSOperationQueuePriorityNormal];
    
    XCTAssertEqual(resolvedConnectionType, ZincConnectionTypeWiFiOnly, @"should allow wifi only");
}

- (void) testThatConnectionTypeIsSetForGreaterPriorityIsCorrectWhenSetForPriority
{
    ZincDownloadPolicy* policy = [[[ZincDownloadPolicy alloc] init] autorelease];
    policy.defaultRequiredConnectionType = ZincConnectionTypeWiFiOnly;
    
    [policy setRequiredConnectionType:ZincConnectionTypeAny forPrioritiesGreaterThanOrEqualToPriority:NSOperationQueuePriorityHigh];
    
    ZincConnectionType resolvedConnectionType = [policy requiredConnectionTypeForPriority:NSOperationQueuePriorityVeryHigh];
    
    XCTAssertEqual(resolvedConnectionType, ZincConnectionTypeAny, @"should allow any connection type");
}

@end
