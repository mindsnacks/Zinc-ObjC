//
//  ZincFunctionalTestCase.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/5/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>

#import "Zinc.h"

@interface ZincFunctionalTestCase : GHAsyncTestCase

@property (strong) ZincRepo *zincRepo;

@end
