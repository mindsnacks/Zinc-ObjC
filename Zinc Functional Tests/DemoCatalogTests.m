//
//  FunctionalTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/5/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincFunctionalTestCase.h"
#import "ZincRepo+Private.h"
#import "ZincJSONSerialization.h"
#import "ZincBundle.h"
#import "ZincUtils.h"

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

    [self prepare];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
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
    
    [self prepare];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];

    ZincBundle *masterBundle = [self.zincRepo bundleWithId:bundleID];
    GHTestLog(@"master bundle version: %d", masterBundle.version);
    
    // -- Update bundle @ test
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"test" automaticallyUpdate:NO];
    
    [self prepare];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
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

- (void)testImportThenDownload
{
    [self refreshCatalog];
    
    NSString *bundleID = ZincBundleIdFromCatalogIdAndBundleName(DEMO_CATALOG_ID, @"cats");
    
    // -- Import
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *manifestPath = [resourcePath stringByAppendingPathComponent:@"cats.json"];
    
    NSError* error = nil;
    BOOL registerSuccess = [self.zincRepo registerExternalBundleWithManifestPath:manifestPath bundleRootPath:resourcePath error:&error];;
    GHAssertTrue(registerSuccess, @"error: %@", error);

    ZincBundleState state = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(state, ZincBundleStateAvailable, @"should be available");
    
    // -- Clone bundle
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"master" automaticallyUpdate:NO];

    [self prepare];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
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

- (void)testBundleDelete
{
    [self refreshCatalog];
    
    NSString *bundleID = ZincBundleIdFromCatalogIdAndBundleName(DEMO_CATALOG_ID, @"cats");
    
    // -- Clone bundle
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"master" automaticallyUpdate:NO];
    
    [self prepare];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];
    
    // -- Verify Available
    
    ZincBundleState bundleState1 = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(bundleState1, ZincBundleStateAvailable, @"bundle should be available");
    
    ZincVersion version = [self.zincRepo versionForBundleId:bundleID distribution:@"master"];
    NSString* bundleRoot = [self.zincRepo pathForBundleWithId:bundleID version:version];

    BOOL rootExists1 = [[NSFileManager defaultManager] fileExistsAtPath:bundleRoot];
    GHAssertTrue(rootExists1, @"bundle should exist");
    
    // -- Stop tracking
    
    [self.zincRepo stopTrackingBundleWithId:bundleID];

    [self prepare];
    [self.zincRepo refreshWithCompletion:^{
        [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];
    
    // -- Wait for the bundle delete task to run
    [self.zincRepo suspendAllTasksAndWaitExecutingTasksToComplete];

    // -- Verify Not Available
    
    ZincBundleState bundleState2 = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertNotEquals(bundleState2, ZincBundleStateAvailable, @"bundle should not be available");
    
    BOOL rootExists2 = [[NSFileManager defaultManager] fileExistsAtPath:bundleRoot];
    GHAssertFalse(rootExists2, @"bundle should have been deleted");
}

- (void)testCleanRemovesBundleWithSymlinksIfVersion1
{
    [self refreshCatalog];
    
    NSError* error = nil;
    
    NSString *bundleID = ZincBundleIdFromCatalogIdAndBundleName(DEMO_CATALOG_ID, @"cats");
    
    // -- Clone bundle
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"master" automaticallyUpdate:NO];
    
    [self prepare];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];
    
    ZincBundleState bundleState1 = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(bundleState1, ZincBundleStateAvailable, @"bundle should be available");

    [self.zincRepo suspendAllTasksAndWaitExecutingTasksToComplete];

    // -- Add a dummy symlink to cause the bundle to be cleaned
    
    ZincVersion version = [self.zincRepo versionForBundleId:bundleID distribution:@"master"];
    NSString* bundleRoot = [self.zincRepo pathForBundleWithId:bundleID version:version];
    
    NSString* symlinkPath = [bundleRoot stringByAppendingPathComponent:@"dummy"];
    
    if (![[NSFileManager defaultManager] createSymbolicLinkAtPath:symlinkPath withDestinationPath:@"nowhere" error:&error]) {
        GHFail(@"failed to create symlink");
    }
    
    // -- Reset the zinc repo
    
    NSString* indexPath = [[self.zincRepo.url path] stringByAppendingPathComponent:@"repo.json"];
    
    NSData* jsonData = [[NSData alloc] initWithContentsOfFile:indexPath options:0 error:&error];
    if (jsonData == nil) {
        GHFail(@"error: %@", error);
    }
    
    NSDictionary* jsonDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (jsonDict == nil) {
        GHFail(@"error: %@", error);
    }
    
    ZincRepoIndex* index = [ZincRepoIndex repoIndexFromDictionary:jsonDict error:&error];
    if (index == nil) {
        GHFail(@"error: %@", error);
    }
    
    index.format = 1;
    
    NSData* indexData = [index jsonRepresentation:&error];
    if (indexData == nil) {
        GHFail(@"error: %@", error);
    }
    
    if (![indexData writeToFile:indexPath atomically:YES]) {
        GHFail(@"failed to write");
    }
        
    self.zincRepo = [ZincRepo repoWithURL:[NSURL fileURLWithPath:[[self.zincRepo url] path]] error:&error];
    GHAssertNil(error, @"error: %@", error);
    self.zincRepo.delegate = self;
    self.zincRepo.autoRefreshInterval = 0;
    [self.zincRepo resumeAllTasks];
    
    // -- Wait for initialization
    
    [self.zincRepo waitForInitialization];
    
    ZincBundleState bundleState2 = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(bundleState2, ZincBundleStateNone, @"bundle should not be available");
}

- (void)testCleanDoesNotRemoveBundleWithSymlinksIfVersionIs2
{
    [self refreshCatalog];
    
    NSString *bundleID = ZincBundleIdFromCatalogIdAndBundleName(DEMO_CATALOG_ID, @"cats");
    
    // -- Clone bundle
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"master" automaticallyUpdate:NO];
    
    [self prepare];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];
    
    ZincBundleState bundleState1 = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(bundleState1, ZincBundleStateAvailable, @"bundle should be available");
    
    // -- Add a dummy symlink to cause the bundle to be cleaned
    
    ZincVersion version = [self.zincRepo versionForBundleId:bundleID distribution:@"master"];
    NSString* bundleRoot = [self.zincRepo pathForBundleWithId:bundleID version:version];
    
    NSString* symlinkPath = [bundleRoot stringByAppendingPathComponent:@"dummy"];
    
    NSError* error = nil;
    if (![[NSFileManager defaultManager] createSymbolicLinkAtPath:symlinkPath withDestinationPath:@"nowhere" error:&error]) {
        GHFail(@"failed to create symlink");
    }
    
    // -- Reset the zinc repo
    
    [self.zincRepo suspendAllTasksAndWaitExecutingTasksToComplete];
    
    self.zincRepo = [ZincRepo repoWithURL:[NSURL fileURLWithPath:[[self.zincRepo url] path]] error:&error];
    GHAssertNil(error, @"error: %@", error);
    self.zincRepo.delegate = self;
    self.zincRepo.autoRefreshInterval = 0;
    [self.zincRepo resumeAllTasks];
    
    // -- Wait for initialization

    [self.zincRepo waitForInitialization];

    ZincBundleState bundleState2 = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(bundleState2, ZincBundleStateAvailable, @"bundle should still be available");
}

- (void)testCleanDoesNotRemoveBundleWithoutSymlinksIfVersionIs1
{
    [self refreshCatalog];
    
    NSError* error = nil;
    
    NSString *bundleID = ZincBundleIdFromCatalogIdAndBundleName(DEMO_CATALOG_ID, @"cats");
    
    // -- Clone bundle
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"master" automaticallyUpdate:NO];

    [self prepare];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];
    
    ZincBundleState bundleState1 = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(bundleState1, ZincBundleStateAvailable, @"bundle should be available");
    
    // -- Reset the zinc repo
    
    [self.zincRepo suspendAllTasksAndWaitExecutingTasksToComplete];
    
    
    NSString* indexPath = [[self.zincRepo.url path] stringByAppendingPathComponent:@"repo.json"];
    
    NSData* jsonData = [[NSData alloc] initWithContentsOfFile:indexPath options:0 error:&error];
    if (jsonData == nil) {
        GHFail(@"error: %@", error);
    }
    
    NSDictionary* jsonDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (jsonDict == nil) {
        GHFail(@"error: %@", error);
    }
    
    ZincRepoIndex* index = [ZincRepoIndex repoIndexFromDictionary:jsonDict error:&error];
    if (index == nil) {
        GHFail(@"error: %@", error);
    }
    
    index.format = 1;
    
    NSData* indexData = [index jsonRepresentation:&error];
    if (indexData == nil) {
        GHFail(@"error: %@", error);
    }
    
    if (![indexData writeToFile:indexPath atomically:YES]) {
        GHFail(@"failed to write");
    }

    self.zincRepo = [ZincRepo repoWithURL:[NSURL fileURLWithPath:[[self.zincRepo url] path]] error:&error];
    GHAssertNil(error, @"error: %@", error);
    self.zincRepo.delegate = self;
    self.zincRepo.autoRefreshInterval = 0;
    [self.zincRepo resumeAllTasks];
    
    // -- Wait for initialization

    [self.zincRepo waitForInitialization];
    
    ZincBundleState bundleState2 = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(bundleState2, ZincBundleStateAvailable, @"bundle should still be available");
}

- (void)testCleanRemovesObjectWithSymlinksIfFlagIfVersionIs1
{
    NSError* error = nil;
    
    [self refreshCatalog];
    
    NSString *bundleID = ZincBundleIdFromCatalogIdAndBundleName(DEMO_CATALOG_ID, @"cats");
    
    // -- Clone bundle
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"master" automaticallyUpdate:NO];

    [self prepare];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];
    
    // -- Add a dummy symlink to cause the bundle to be cleaned
    
    NSString* objectRoot = [self.zincRepo filesPath];
    NSString* symlinkPath = [objectRoot stringByAppendingPathComponent:@"dummy"];
    
    if (![[NSFileManager defaultManager] createSymbolicLinkAtPath:symlinkPath withDestinationPath:@"nowhere" error:&error]) {
        GHFail(@"failed to create symlink");
    }
    
    // -- Reset the zinc repo
    
    [self.zincRepo suspendAllTasksAndWaitExecutingTasksToComplete];
    
    
    NSString* indexPath = [[self.zincRepo.url path] stringByAppendingPathComponent:@"repo.json"];
    
    NSData* jsonData = [[NSData alloc] initWithContentsOfFile:indexPath options:0 error:&error];
    if (jsonData == nil) {
        GHFail(@"error: %@", error);
    }
    
    NSDictionary* jsonDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (jsonDict == nil) {
        GHFail(@"error: %@", error);
    }
    
    ZincRepoIndex* index = [ZincRepoIndex repoIndexFromDictionary:jsonDict error:&error];
    if (index == nil) {
        GHFail(@"error: %@", error);
    }
    
    index.format = 1;
    
    NSData* indexData = [index jsonRepresentation:&error];
    if (indexData == nil) {
        GHFail(@"error: %@", error);
    }
    
    if (![indexData writeToFile:indexPath atomically:YES]) {
        GHFail(@"failed to write");
    }
    
    self.zincRepo = [ZincRepo repoWithURL:[NSURL fileURLWithPath:[[self.zincRepo url] path]] error:&error];
    GHAssertNil(error, @"error: %@", error);
    self.zincRepo.delegate = self;
    self.zincRepo.autoRefreshInterval = 0;
    [self.zincRepo resumeAllTasks];
    
    // -- Wait for initialization

    [self.zincRepo waitForInitialization];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:symlinkPath];
    GHAssertFalse(fileExists, @"file should not exist");    
}

- (void)testCleanDoesNotRemoveObjectWithSymlinksIfVersionIs2
{
    [self refreshCatalog];
    
    NSString *bundleID = ZincBundleIdFromCatalogIdAndBundleName(DEMO_CATALOG_ID, @"cats");
    
    // -- Clone bundle
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"master" automaticallyUpdate:NO];

    [self prepare];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];
    
    // -- Add a dummy symlink to cause the bundle to be cleaned
    
    NSString* objectRoot = [self.zincRepo filesPath];
    NSString* symlinkPath = [objectRoot stringByAppendingPathComponent:@"dummy"];
    
    NSError* error = nil;
    if (![[NSFileManager defaultManager] createSymbolicLinkAtPath:symlinkPath withDestinationPath:@"nowhere" error:&error]) {
        GHFail(@"failed to create symlink");
    }
    
    // -- Reset the zinc repo
    
    [self.zincRepo suspendAllTasksAndWaitExecutingTasksToComplete];
    
    self.zincRepo = [ZincRepo repoWithURL:[NSURL fileURLWithPath:[[self.zincRepo url] path]] error:&error];
    GHAssertNil(error, @"error: %@", error);
    self.zincRepo.delegate = self;
    self.zincRepo.autoRefreshInterval = 0;
    [self.zincRepo resumeAllTasks];

    // -- Wait for initialization

    [self.zincRepo waitForInitialization];
    
    NSNumber* isSymlink;
    if (![[NSURL fileURLWithPath:symlinkPath] getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:&error]) {
        GHFail(@"%@", error);
    }
    
    GHAssertTrue([isSymlink boolValue], @"should exist");
}

- (void)testMissingBundleDir
{
    [self refreshCatalog];
    
    NSString *bundleID = ZincBundleIdFromCatalogIdAndBundleName(DEMO_CATALOG_ID, @"cats");
    
    // -- Clone bundle
    
    [self.zincRepo beginTrackingBundleWithId:bundleID distribution:@"master" automaticallyUpdate:NO];

    [self prepare];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:DEFAULT_TIMEOUT_SECONDS];

    // -- Remove bundle files
    
    ZincVersion version = [self.zincRepo versionForBundleId:bundleID distribution:@"master"];
    NSString* bundleRoot = [self.zincRepo pathForBundleWithId:bundleID version:version];
    
    NSError* deleteError = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:bundleRoot error:&deleteError]) {
        GHFail(@"error: %@", deleteError);
    }
    
    ZincBundle* bundle = [self.zincRepo bundleWithId:bundleID];
    GHAssertNil(bundle, @"bundle should be nil");
    
    ZincBundleState state = [self.zincRepo stateForBundleWithId:bundleID];
    GHAssertEquals(state, ZincBundleStateNone, @"should not be available");
}

@end
