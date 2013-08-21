//
//  ZincFunctionalTestCase.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/5/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>

#import "ZincRepo.h"

@interface ZincRepoFunctionalTestCase : GHAsyncTestCase <ZincRepoEventListener>

@property (strong) ZincRepo *zincRepo;


/**
 @discussion Sets up a test zinc repo at the specificied location
 */
- (void)setupZincRepoWithRootDir:(NSString*)repoDir;

/**
 @discussion Sets up a test zinc repo in a unique temporary directory
 */
- (void)setupZincRepo;


@end
