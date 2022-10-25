//
//  ZincUtilsTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/26/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincUtils.h"


@interface ZincUtilsTests : XCTestCase
@end


@implementation ZincUtilsTests

- (void) testBundleIdentifierParsing
{
    XCTAssertEqualObjects(ZincBundleNameFromBundleID(@"mindsnacks.assets"), @"assets", @"should be 'assets'");
    XCTAssertEqualObjects(ZincCatalogIDFromBundleID(@"mindsnacks.assets"), @"mindsnacks", @"should be 'mindsnacks'");

    XCTAssertEqualObjects(ZincBundleNameFromBundleID(@"com.mindsnacks.assets"), @"assets", @"should be 'assets'");
    XCTAssertEqualObjects(ZincCatalogIDFromBundleID(@"com.mindsnacks.assets"), @"com.mindsnacks", @"should be 'com.mindsnacks'");
}

@end
