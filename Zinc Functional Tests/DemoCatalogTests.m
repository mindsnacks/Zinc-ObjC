//
//  FunctionalTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/5/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincFunctionalTestCase.h"
#import "ZincRepo+Private.h"

#define DEMO_CATALOG_URL [NSURL URLWithString:@"https://s3.amazonaws.com/zinc-demo/com.mindsnacks.demo1/"]
#define DEMO_CATALOG_ID @"com.mindsnacks.demo1"
#define DEFAULT_TIMEOUT_SECONDS 60

@interface DemoCatalogTests : ZincFunctionalTestCase

@end

@implementation DemoCatalogTests

- (void)setUp
{
    [self setupZincRepo];
    
    [self.zincRepo addSourceURL:DEMO_CATALOG_URL];
}

- (void)refreshCatalog
{
    dispatch_group_t dispatchGroup =  dispatch_group_create();
    
    dispatch_group_enter(dispatchGroup);
    
    [self.zincRepo refreshSourcesWithCompletion:^{
        dispatch_group_leave(dispatchGroup);
        
    }];
    
    dispatch_group_wait(dispatchGroup, dispatch_time(DISPATCH_TIME_NOW, DEFAULT_TIMEOUT_SECONDS * NSEC_PER_SEC));
}

/*
 * Clones the "cats" bundle, using manual update
 */
- (void)testSimpleManualClone
{
    [self refreshCatalog];

    NSString *bundleID = ZincBundleIdFromCatalogIdAndBundleName(DEMO_CATALOG_ID, @"cats");
    
    // -- Clone bundle
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"master" automaticallyUpdate:NO];
    
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    
    [self prepare];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];
    
    // -- Verify
    
    ZincBundleState bundleState = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(bundleState, ZincBundleStateAvailable, @"bundle should be available");
}

/*
 * Clones the "cats" bundle, using manual update
 */
- (void)testSwitchDistros
{
    [self refreshCatalog];
 
    NSString *bundleID = ZincBundleIdFromCatalogIdAndBundleName(DEMO_CATALOG_ID, @"dogs");
    
    // -- Update bundle @ master
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"master" automaticallyUpdate:NO];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    [self prepare];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];

    ZincBundle *masterBundle = [self.zincRepo bundleWithId:bundleID];
    GHTestLog(@"master bundle version: %d", masterBundle.version);
    
    // -- Update bundle @ test
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"test" automaticallyUpdate:NO];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    [self prepare];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];

    ZincBundle *testBundle = [self.zincRepo bundleWithId:bundleID];
    GHTestLog(@"test bundle version: %d", testBundle.version);
    
    // -- Verify
    
    ZincBundleState masterState = [self.zincRepo.index stateForBundle:[masterBundle resource]];
    GHAssertEquals(masterState, ZincBundleStateAvailable, @"master should be available");
    
    ZincBundleState testState = [self.zincRepo.index stateForBundle:[testBundle resource]];
    GHAssertEquals(testState, ZincBundleStateAvailable, @"test should be available");
    
    GHAssertNotEquals(masterBundle.version, testBundle.version, @"bundle versions should not be equal");
}

- (void)testBootstrapThenDownload
{
    [self refreshCatalog];
    
    NSString *bundleID = ZincBundleIdFromCatalogIdAndBundleName(DEMO_CATALOG_ID, @"cats");
    
    // -- Bootstrap
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *manifestPath = [resourcePath stringByAppendingPathComponent:@"cats.json"];
    
    ZincTaskRef* taskRef = [self.zincRepo registerExternalBundleWithManifestPath:manifestPath bundleRootPath:resourcePath];
    GHAssertTrue([taskRef isValid], @"taskRefShouldBeValid");
    [taskRef waitUntilFinished];
    GHAssertTrue([taskRef isSuccessful], @"errors: %@", [taskRef allErrors]);

    ZincBundleState state = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(state, ZincBundleStateAvailable, @"should be available");
    
    // -- Clone bundle
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"master" automaticallyUpdate:NO];
    
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    
    [self prepare];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];
    
    // -- Verify
    
    ZincBundleState bundleState = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(bundleState, ZincBundleStateAvailable, @"bundle should be available");
    
    ZincBundle *catsBundle = [self.zincRepo bundleWithId:bundleID];
    GHAssertFalse(catsBundle.version == 0, @"should not be v0");
    
    UIImage *image1 = [UIImage imageWithContentsOfFile:[catsBundle pathForResource:@"kucing.jpeg"]];
    GHAssertNotNil(image1, @"image should not be nil");
    
    UIImage *image2 = [UIImage imageWithContentsOfFile:[catsBundle pathForResource:@"lime-cat.jpeg"]];
    GHAssertNotNil(image2, @"image should not be nil");
}

@end
