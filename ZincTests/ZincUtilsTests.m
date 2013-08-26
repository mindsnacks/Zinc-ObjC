//
//  ZincUtilsTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/26/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincUtilsTests.h"
#import "ZincUtils.h"

@implementation ZincUtilsTests

- (void) testBundleIdentifierParsing
{
    STAssertEqualObjects(ZincBundleNameFromBundleID(@"mindsnacks.assets"), @"assets", @"should be 'assets'");
    STAssertEqualObjects(ZincCatalogIDFromBundleID(@"mindsnacks.assets"), @"mindsnacks", @"should be 'mindsnacks'");

    STAssertEqualObjects(ZincBundleNameFromBundleID(@"com.mindsnacks.assets"), @"assets", @"should be 'assets'");
    STAssertEqualObjects(ZincCatalogIDFromBundleID(@"com.mindsnacks.assets"), @"com.mindsnacks", @"should be 'com.mindsnacks'");
}

@end
