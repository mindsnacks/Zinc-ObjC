//
//  ZincFileManagerTest.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/30/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincSHA.h"
#import "NSFileManager+Zinc.h"


@interface ZincFileManagerTest : XCTestCase
@end


@implementation ZincFileManagerTest

// TODO: move this into a new test suite
- (void)testSha1
{
    NSString* path = [TEST_RESOURCE_ROOT_PATH stringByAppendingPathComponent:@"360px-Grey_square_optical_illusion.png"];   
    
    NSString* sha = ZincSHA1HashFromPath(path, 0, NULL);
    
    XCTAssertNotNil(sha, @"sha is nil");
    XCTAssertEqualObjects(sha, @"f0d25f7505e777633104888e88c68e9b9655f62f", @"sha is wrong");
}

- (void)testMoveItemAtPath_DstDoesNotExist_FailIfExists
{
    NSError* error = nil;

    NSString* src = TEST_TMP_PATH(@"src", @"txt");
    if (![@"pineapple" writeToFile:src atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        XCTFail(@"error: %@", error);
    }

    NSString* dst = TEST_TMP_PATH(@"dst", @"txt");

    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL srcExists = [fm fileExistsAtPath:src];
    BOOL dstExists = [fm fileExistsAtPath:dst];

    XCTAssertTrue(srcExists, @"src should exist");
    XCTAssertFalse(dstExists, @"dst should no exist");

    BOOL moveSuccess = [fm zinc_moveItemAtPath:src toPath:dst failIfExists:YES error:&error];
    XCTAssertTrue(moveSuccess, @"should succeed: %@", error);

    [fm removeItemAtPath:src error:NULL];
    [fm removeItemAtPath:dst error:NULL];
}

- (void)testMoveItemAtPath_DstDoesExist_FailIfExists
{
    NSError* error = nil;

    NSString* src = TEST_TMP_PATH(@"src", @"txt");
    if (![@"pineapple" writeToFile:src atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        XCTFail(@"error: %@", error);
    }

    NSString* dst = TEST_TMP_PATH(@"dst", @"txt");
    if (![@"grapefruit" writeToFile:dst atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        XCTFail(@"error: %@", error);
    }

    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL srcExists = [fm fileExistsAtPath:src];
    BOOL dstExists = [fm fileExistsAtPath:dst];

    XCTAssertTrue(srcExists, @"src should exist");
    XCTAssertTrue(dstExists, @"dst should no exist");

    BOOL moveSuccess = [fm zinc_moveItemAtPath:src toPath:dst failIfExists:YES error:&error];
    XCTAssertFalse(moveSuccess, @"should succeed: %@", error);

    [fm removeItemAtPath:src error:NULL];
    [fm removeItemAtPath:dst error:NULL];
}

- (void)testMoveItemAtPath_DstDoesNotExist_NotFailIfExists
{
    NSError* error = nil;

    NSString* src = TEST_TMP_PATH(@"src", @"txt");
    if (![@"pineapple" writeToFile:src atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        XCTFail(@"error: %@", error);
    }

    NSString* dst = TEST_TMP_PATH(@"dst", @"txt");

    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL srcExists = [fm fileExistsAtPath:src];
    BOOL dstExists = [fm fileExistsAtPath:dst];

    XCTAssertTrue(srcExists, @"src should exist");
    XCTAssertFalse(dstExists, @"dst should no exist");

    BOOL moveSuccess = [fm zinc_moveItemAtPath:src toPath:dst failIfExists:NO error:&error];
    XCTAssertTrue(moveSuccess, @"should succeed: %@", error);

    [fm removeItemAtPath:src error:NULL];
    [fm removeItemAtPath:dst error:NULL];
}

- (void)testMoveItemAtPath_DstDoesExist_NotFailIfExists
{
    NSError* error = nil;

    NSString* src = TEST_TMP_PATH(@"src", @"txt");
    if (![@"pineapple" writeToFile:src atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        XCTFail(@"error: %@", error);
    }

    NSString* dst = TEST_TMP_PATH(@"dst", @"txt");
    if (![@"grapefruit" writeToFile:dst atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        XCTFail(@"error: %@", error);
    }

    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL srcExists = [fm fileExistsAtPath:src];
    BOOL dstExists = [fm fileExistsAtPath:dst];

    XCTAssertTrue(srcExists, @"src should exist");
    XCTAssertTrue(dstExists, @"dst should no exist");

    BOOL moveSuccess = [fm zinc_moveItemAtPath:src toPath:dst failIfExists:NO error:&error];
    XCTAssertTrue(moveSuccess, @"should succeed: %@", error);

    [fm removeItemAtPath:src error:NULL];
    [fm removeItemAtPath:dst error:NULL];
}




@end
