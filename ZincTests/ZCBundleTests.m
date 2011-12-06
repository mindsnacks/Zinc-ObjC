//
//  ZCBundleTests.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZCBundleTests.h"
#import "ZCBundle.h"
#import "ZCBundle+Private.h"
#import "NSFileManager+Zinc.h"

@implementation ZCBundleTests

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


@end
