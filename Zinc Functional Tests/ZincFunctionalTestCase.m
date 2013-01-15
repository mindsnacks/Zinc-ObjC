//
//  ZincFunctionalTestCase.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/5/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincFunctionalTestCase.h"

@implementation ZincFunctionalTestCase

- (void)setupZincRepoWithRootDir:(NSString*)repoDir
{
    NSError *error = nil;
    self.zincRepo = [ZincRepo repoWithURL:[NSURL fileURLWithPath:repoDir] error:&error];
    GHAssertNil(error, @"error: %@", error);

    self.zincRepo.autoRefreshInterval = 0;
    [self.zincRepo resumeAllTasks];

    GHTestLog(@"ZincRepo: %@", [self.zincRepo.url path]);
}

- (void)setupZincRepo
{
    NSString *repoDir = ZincGetUniqueTemporaryDirectory();
    [self setupZincRepoWithRootDir:repoDir];
    
}


@end
