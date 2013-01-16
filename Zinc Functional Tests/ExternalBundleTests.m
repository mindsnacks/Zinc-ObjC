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
    
    ZincBundleState state = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(state, ZincBundleStateAvailable, @"should be available");
    
    // -- verify data
    
    ZincBundle *catsBundle = [self.zincRepo bundleWithId:bundleID];
    
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
    
    NSString *manifestPath2 = [self.zincRepo pathForManifestWithBundleId:bundleID version:0];
    
    GHAssertEqualStrings(manifestPath1, manifestPath2, @"paths are wrong");
}



// TODO: think this is no longer valid
//- (void)testDeleteOriginalsAndImportAgain
//{
//    NSString* bundleId = @"com.mindsnacks.demo1.cats";
//    
//    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
//    NSString *manifestPath = [resourcePath stringByAppendingPathComponent:@"cats.json"];
//    
//    NSError *error = nil;
//    ZincManifest *manifest = [ZincManifest manifestWithPath:manifestPath error:&error];
//    GHAssertNotNil(manifestPath, @"error: %@", error);
//    
//    // -- create a temp dir and copy all the files
//    
//    NSString *bundleRootPath1 = ZincGetUniqueTemporaryDirectory();
//    
//    for (NSString *file in [manifest allFiles]) {
//        
//        NSString *sourcePath = [[NSBundle mainBundle] pathForResource:file];
//        NSString *destPath = [bundleRootPath1 stringByAppendingPathComponent:file];
//        
//        if (![[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destPath error:&error]) {
//            GHFail(@"@%", error);
//        }
//    }
//    
//    // -- register the files from the temp location
//    
//    BOOL registerSuccess1 = [self.zincRepo registerExternalBundleWithManifestPath:manifestPath
//                                                                   bundleRootPath:bundleRootPath1
//                                                                            error:&error];
//    GHAssertTrue(registerSuccess1, @"error:", error);
//    
//    // -- make sure the files are available
//    
//    ZincBundle *catsBundle1 = [self.zincRepo bundleWithId:bundleId];
//    
//    UIImage *cute1 = [UIImage imageWithContentsOfFile:[catsBundle1 pathForResource:@"kucing.jpeg"]];
//    GHAssertNotNil(cute1, @"image should not be nil");
//    
//    UIImage *lime1 = [UIImage imageWithContentsOfFile:[catsBundle1 pathForResource:@"lime-cat.jpeg"]];
//    GHAssertNotNil(lime1, @"image should not be nil");
//    
//    // -- now delete the originals
//    
//    if (![[NSFileManager defaultManager] removeItemAtPath:bundleRootPath1 error:&error]) {
//        GHFail(@"%@", error);
//    }
//    
//    // -- re-register the bundle from the files inside the main bundle
//    
//    [self setupZincRepoWithRootDir:[[self.zincRepo url] path]];
//    
//    BOOL registerSuccess2 = [self.zincRepo registerExternalBundleWithManifestPath:manifestPath
//                                                                   bundleRootPath:bundleRootPath1
//                                                                            error:&error];
//    GHAssertTrue(registerSuccess2, @"error:", error);
//    
//    ZincBundleState state = [self.zincRepo stateForBundleWithId:bundleId];
//    GHAssertEquals(state, ZincBundleStateAvailable, @"should be available");
//    
//    // -- verify data
//    
//    ZincBundle *catsBundle2 = [self.zincRepo bundleWithId:bundleId];
//    
//    UIImage *cute2 = [UIImage imageWithContentsOfFile:[catsBundle2 pathForResource:@"kucing.jpeg"]];
//    GHAssertNotNil(cute2, @"image should not be nil");
//    
//    UIImage *lime2 = [UIImage imageWithContentsOfFile:[catsBundle2 pathForResource:@"lime-cat.jpeg"]];
//    GHAssertNotNil(lime2, @"image should not be nil");
//}

@end
