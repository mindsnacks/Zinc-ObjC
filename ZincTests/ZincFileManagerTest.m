//
//  ZincFileManagerTest.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/30/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincFileManagerTest.h"
#import "NSFileManager+Zinc.h"

@implementation ZincFileManagerTest

// All code under test must be linked into the Unit Test bundle
//- (void)testMath
//{
//    STAssertTrue((1 + 1) == 2, @"Compiler isn't feeling well today :-(");
//}

- (void)testSha1
{
    NSString* path = [TEST_RESOURCE_ROOT_PATH stringByAppendingPathComponent:@"360px-Grey_square_optical_illusion.png"];   
    
    NSString* sha = [[NSFileManager defaultManager] zinc_sha1ForPath:path];
    
    STAssertNotNil(sha, @"sha is nil");
    STAssertEqualObjects(sha, @"f0d25f7505e777633104888e88c68e9b9655f62f", @"sha is wrong");
}


@end
