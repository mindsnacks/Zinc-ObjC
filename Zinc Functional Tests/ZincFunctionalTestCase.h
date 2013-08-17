//
//  ZincFunctionalTestCase.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/5/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>

#import "ZincRepo.h"
#import "ZincAgent.h"

@interface ZincFunctionalTestCase : GHAsyncTestCase <ZincRepoDelegate>

@property (strong) ZincRepo *zincRepo;
@property (strong) ZincAgent *zincAgent;


/**
 @discussion Sets up a test zinc repo at the specificied location
 */
- (void)setupZincRepoWithRootDir:(NSString*)repoDir;

/**
 @discussion Sets up a test zinc repo in a unique temporary directory
 */
- (void)setupZincRepo;


@end
