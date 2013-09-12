//
//  ZincAgentTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/17/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincAgent.h"
#import "ZincRepo.h"


@interface ZincAgentTests : SenTestCase
@end


@implementation ZincAgentTests

- (void)testGetsTheSameAgent
{
    id repo = [OCMockObject niceMockForClass:[ZincRepo class]];
    [[[repo stub] andReturn:[NSURL URLWithString:@"file:///tmp"]] url];

    ZincAgent* agent1 = [ZincAgent agentForRepo:repo];
    ZincAgent* agent2 = [ZincAgent agentForRepo:repo];

    STAssertEquals(agent1, agent2, @"should be the same object");
}

@end
