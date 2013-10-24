//
//  ZincAgentFunctionalTestCase.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/18/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>

#import "ZincRepoFunctionalTestCase.h"
#import "ZincAgent.h"

@interface ZincAgentFunctionalTestCase : ZincRepoFunctionalTestCase

@property (strong) ZincAgent *zincAgent;

@end
