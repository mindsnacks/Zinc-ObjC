//
//  ZincDownloadPolicyTest.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/21/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincDownloadPolicyTest.h"
#import "ZincDownloadPolicy.h"

@implementation ZincDownloadPolicyTest

- (void) testThatConnectionTypeIsNotSetForLesserPriorityIsCorrectWhenSetForPriority
{
    ZincDownloadPolicy* policy = [[[ZincDownloadPolicy alloc] init] autorelease];
    policy.defaultRequiredConnectionType = ZincConnectionTypeWiFiOnly;
    
    [policy setRequiredConnectionType:ZincConnectionTypeAny forPrioritiesGreaterThanOrEqualToPriority:NSOperationQueuePriorityHigh];
    
    ZincConnectionType resolvedConnectionType = [policy requiredConnectionTypeForPriority:NSOperationQueuePriorityNormal];
    
    STAssertEquals(resolvedConnectionType, ZincConnectionTypeWiFiOnly, @"should allow wifi only");
}

- (void) testThatConnectionTypeIsSetForGreaterPriorityIsCorrectWhenSetForPriority
{
    ZincDownloadPolicy* policy = [[[ZincDownloadPolicy alloc] init] autorelease];
    policy.defaultRequiredConnectionType = ZincConnectionTypeWiFiOnly;
    
    [policy setRequiredConnectionType:ZincConnectionTypeAny forPrioritiesGreaterThanOrEqualToPriority:NSOperationQueuePriorityHigh];
    
    ZincConnectionType resolvedConnectionType = [policy requiredConnectionTypeForPriority:NSOperationQueuePriorityVeryHigh];
    
    STAssertEquals(resolvedConnectionType, ZincConnectionTypeAny, @"should allow any connection type");
}

@end
