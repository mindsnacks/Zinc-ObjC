//
//  ImportTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/5/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincFunctionalTestCase.h"
#import "ZincRepo+Private.h"
#import "ZincManifest.h"
#import "ZincUtils.h"
#import "ZincResource.h"
#import "ZincBundle.h"

@interface ExternalBundleTests : ZincFunctionalTestCase

@end


@implementation ExternalBundleTests

- (void)setUp
{
    [self setupZincRepo];
}

- (void)testBasicExternalBundle
{
    NSString* bundleID = @"com.mindsnacks.demo1.cats";
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *manifestPath = [resourcePath stringByAppendingPathComponent:@"cats.json"];
    
    NSError* error = nil;
    BOOL registerSuccess = [self.zincRepo registerExternalBundleWithManifestPath:manifestPath bundleRootPath:resourcePath error:&error];
    GHAssertTrue(registerSuccess, @"error:", error);
    
    ZincBundleState state = [self.zincRepo stateForBundleWithID:bundleID];
    GHAssertEquals(state, ZincBundleStateAvailable, @"should be available");
    
    // -- verify data
    
    ZincBundle *catsBundle = [self.zincRepo bundleWithID:bundleID];
    
    UIImage *image1 = [UIImage imageWithContentsOfFile:[catsBundle pathForResource:@"kucing.jpeg"]];
    GHAssertNotNil(image1, @"image should not be nil");
    
    UIImage *image2 = [UIImage imageWithContentsOfFile:[catsBundle pathForResource:@"lime-cat.jpeg"]];
    GHAssertNotNil(image2, @"image should not be nil");
}

- (void)testManifestPathIsExternal
{
    NSString* bundleID = @"com.mindsnacks.demo1.cats";
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *manifestPath1 = [resourcePath stringByAppendingPathComponent:@"cats.json"];
    
    NSError* error = nil;
    BOOL registerSuccess = [self.zincRepo registerExternalBundleWithManifestPath:manifestPath1 bundleRootPath:resourcePath error:&error];
    GHAssertTrue(registerSuccess, @"error:", error);
    
    NSString *manifestPath2 = [self.zincRepo pathForManifestWithBundleID:bundleID version:0];
    
    GHAssertEqualStrings(manifestPath1, manifestPath2, @"paths are wrong");
}

@end
