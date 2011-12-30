//
//  ZCBundleTests.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincBundleTests.h"
#import "ZincBundle.h"
#import "ZincBundle+Private.h"
#import "NSFileManager+Zinc.h"

@implementation ZincBundleTests

#pragma mark Utility

- (NSString*) createEmptyZincBundleWithFormat:(NSInteger)format
{
    NSError* error = nil;
    NSString* path = TEST_CREATE_TMP_DIR(@"zincbundle");
    NSString* formatString = [NSString stringWithFormat:@"%d", format];
    NSString* formatPath = [path stringByAppendingPathComponent:@"zinc_format.txt"];
    if (![formatString writeToFile:formatPath atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        STFail(@"%@", error);
        return nil;
    }
    return path;
}

#pragma mark Tests

//- (void) testReadFormat1
//{
//    NSError* error = nil;
//    NSString* path = [self createEmptyZincBundleWithFormat:1];
//    ZincFormat format = [ZCBundle readZincFormatFromURL:[NSURL fileURLWithPath:path] error:&error];
//    if (format == ZincFormatInvalid) {
//        STFail(@"%@", error);
//    } else {
//        STAssertTrue(format == 1, @"format wrong");
//    }
//}

- (void) testBundleIdentifierParsing
{
    STAssertEqualObjects([ZincBundle nameFromBundleIdentifier:@"mindsnacks.assets"], @"assets", @"should be 'assets'");
    STAssertEqualObjects([ZincBundle sourceFromBundleIdentifier:@"mindsnacks.assets"], @"mindsnacks", @"should be 'mindsnacks'");
    
    STAssertEqualObjects([ZincBundle nameFromBundleIdentifier:@"com.mindsnacks.assets"], @"assets", @"should be 'assets'");
    STAssertEqualObjects([ZincBundle sourceFromBundleIdentifier:@"com.mindsnacks.assets"], @"com.mindsnacks", @"should be 'com.mindsnacks'");
}


@end
