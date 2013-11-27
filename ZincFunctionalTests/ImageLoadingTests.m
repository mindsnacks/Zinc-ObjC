//
//  ImageLoadingTestCase.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/5/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>

#import "UIImage+Zinc.h"
#import "TestUtility-Zinc.h"

@interface ImageLoadingTests : GHTestCase

@end

@implementation ImageLoadingTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void) testBundleImageLoading
{
    // NOTE: this should be a unit test, but they don't execute in the same
    // environment so I'm adding a little something here

    NSError* error = nil;

    NSString* dstDir = TEST_CREATE_TMP_DIR(@"testimages");
    [[NSFileManager defaultManager] removeItemAtPath:dstDir error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:dstDir withIntermediateDirectories:YES attributes:nil error:&error];
    NSAssert(error==nil, @"failed to create dir");

    for (NSString* file in [NSArray arrayWithObjects:@"sphalerite.jpg", @"sphalerite@2x.jpg", nil]) {
        if (![[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:file ofType:nil] toPath:[dstDir stringByAppendingPathComponent:file] error:&error]) {
            NSLog(@"error: %@", error);
            abort();
        }
    }

    NSBundle* bundle = [NSBundle bundleWithPath:dstDir];
    UIImage* image1 = [UIImage zinc_imageNamed:@"sphalerite.jpg" inBundle:bundle];
    NSAssert(image1, @"image1 is nil");
    NSLog(@"image1: %@", NSStringFromCGSize(image1.size));
    NSAssert(image1.scale == [UIScreen mainScreen].scale, @"image1 scale wrong");

    UIImage* image2 = [UIImage zinc_imageNamed:@"sphalerite@2x.jpg" inBundle:bundle];
    NSAssert(image2, @"image2 is nil");
    NSLog(@"image2: %@", NSStringFromCGSize(image2.size));
    NSAssert(image2.scale == [UIScreen mainScreen].scale, @"image2 scale wrong");
}


@end
