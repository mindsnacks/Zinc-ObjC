//
//  ZincAgentFunctionalTestCase.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/18/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincAgentFunctionalTestCase.h"

@implementation ZincAgentFunctionalTestCase

- (void)tearDown
{
    self.zincAgent = nil;
    [super tearDown];
}

- (void)setupZincRepoWithRootDir:(NSString*)repoDir
{
    [super setupZincRepoWithRootDir:repoDir];

    self.zincAgent = [ZincAgent agentForRepo:self.zincRepo];
}


@end
