//
//  ZincFileManagerTest.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/30/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincSHA.h"
#import "NSFileManager+Zinc.h"


@interface ZincFileManagerTest : SenTestCase
@end


@implementation ZincFileManagerTest

// TODO: move this into a new test suite
- (void)testSha1
{
    NSString* path = [TEST_RESOURCE_ROOT_PATH stringByAppendingPathComponent:@"360px-Grey_square_optical_illusion.png"];   
    
    NSString* sha = ZincSHA1HashFromPath(path, 0, NULL);
    
    STAssertNotNil(sha, @"sha is nil");
    STAssertEqualObjects(sha, @"f0d25f7505e777633104888e88c68e9b9655f62f", @"sha is wrong");
}

- (void)testMoveItemAtPath_DstDoesNotExist_FailIfExists
{
    NSError* error = nil;

    NSString* src = TEST_TMP_PATH(@"src", @"txt");
    if (![@"pineapple" writeToFile:src atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        STFail(@"error: %@", error);
    }

    NSString* dst = TEST_TMP_PATH(@"dst", @"txt");

    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL srcExists = [fm fileExistsAtPath:src];
    BOOL dstExists = [fm fileExistsAtPath:dst];

    STAssertTrue(srcExists, @"src should exist");
    STAssertFalse(dstExists, @"dst should no exist");

    BOOL moveSuccess = [fm zinc_moveItemAtPath:src toPath:dst failIfExists:YES error:&error];
    STAssertTrue(moveSuccess, @"should succeed: %@", error);

    [fm removeItemAtPath:src error:NULL];
    [fm removeItemAtPath:dst error:NULL];
}

- (void)testMoveItemAtPath_DstDoesExist_FailIfExists
{
    NSError* error = nil;

    NSString* src = TEST_TMP_PATH(@"src", @"txt");
    if (![@"pineapple" writeToFile:src atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        STFail(@"error: %@", error);
    }

    NSString* dst = TEST_TMP_PATH(@"dst", @"txt");
    if (![@"grapefruit" writeToFile:dst atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        STFail(@"error: %@", error);
    }

    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL srcExists = [fm fileExistsAtPath:src];
    BOOL dstExists = [fm fileExistsAtPath:dst];

    STAssertTrue(srcExists, @"src should exist");
    STAssertTrue(dstExists, @"dst should no exist");

    BOOL moveSuccess = [fm zinc_moveItemAtPath:src toPath:dst failIfExists:YES error:&error];
    STAssertFalse(moveSuccess, @"should succeed: %@", error);

    [fm removeItemAtPath:src error:NULL];
    [fm removeItemAtPath:dst error:NULL];
}

- (void)testMoveItemAtPath_DstDoesNotExist_NotFailIfExists
{
    NSError* error = nil;

    NSString* src = TEST_TMP_PATH(@"src", @"txt");
    if (![@"pineapple" writeToFile:src atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        STFail(@"error: %@", error);
    }

    NSString* dst = TEST_TMP_PATH(@"dst", @"txt");

    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL srcExists = [fm fileExistsAtPath:src];
    BOOL dstExists = [fm fileExistsAtPath:dst];

    STAssertTrue(srcExists, @"src should exist");
    STAssertFalse(dstExists, @"dst should no exist");

    BOOL moveSuccess = [fm zinc_moveItemAtPath:src toPath:dst failIfExists:NO error:&error];
    STAssertTrue(moveSuccess, @"should succeed: %@", error);

    [fm removeItemAtPath:src error:NULL];
    [fm removeItemAtPath:dst error:NULL];
}

- (void)testMoveItemAtPath_DstDoesExist_NotFailIfExists
{
    NSError* error = nil;

    NSString* src = TEST_TMP_PATH(@"src", @"txt");
    if (![@"pineapple" writeToFile:src atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        STFail(@"error: %@", error);
    }

    NSString* dst = TEST_TMP_PATH(@"dst", @"txt");
    if (![@"grapefruit" writeToFile:dst atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        STFail(@"error: %@", error);
    }

    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL srcExists = [fm fileExistsAtPath:src];
    BOOL dstExists = [fm fileExistsAtPath:dst];

    STAssertTrue(srcExists, @"src should exist");
    STAssertTrue(dstExists, @"dst should no exist");

    BOOL moveSuccess = [fm zinc_moveItemAtPath:src toPath:dst failIfExists:NO error:&error];
    STAssertTrue(moveSuccess, @"should succeed: %@", error);

    [fm removeItemAtPath:src error:NULL];
    [fm removeItemAtPath:dst error:NULL];
}




@end
