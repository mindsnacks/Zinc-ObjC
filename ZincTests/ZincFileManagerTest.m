//
//  ZincFileManagerTest.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/30/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincFileManagerTest.h"
#import "ZincSHA.h"

@implementation ZincFileManagerTest

// TODO: move this into a new test suite
- (void)testSha1
{
    NSString* path = [TEST_RESOURCE_ROOT_PATH stringByAppendingPathComponent:@"360px-Grey_square_optical_illusion.png"];   
    
    NSString* sha = ZincSHA1HashFromPath(path, 0, NULL);
    
    STAssertNotNil(sha, @"sha is nil");
    STAssertEqualObjects(sha, @"f0d25f7505e777633104888e88c68e9b9655f62f", @"sha is wrong");
}


@end
