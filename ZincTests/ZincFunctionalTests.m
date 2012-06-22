//
//  ZincTests.m
//  ZincTests
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincFunctionalTests.h"
#import "ZincRepo.h"
#import "ZincEvent.h"
#import "ZincResource.h"
#import "ZincManifest.h"
#import "ZincRepo+Private.h"

@interface NSMutableArray (ZincTestEventCollector) <ZincRepoDelegate>
- (void) zincRepo:(ZincRepo*)repo didReceiveEvent:(ZincEvent*)event;
- (NSArray*) eventsOfType:(NSInteger)type;
- (BOOL) didReceiveEventOfType:(NSInteger)type;
@end

@implementation NSMutableArray (ZincTestEventCollector)

- (void) zincRepo:(ZincRepo*)repo didReceiveEvent:(ZincEvent*)event
{
    NSLog(@"%@", event);
    [self addObject:event];
}

- (NSArray*) eventsOfType:(NSInteger)type
{
    return [self filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"type = %d", type]];
}

- (BOOL) didReceiveEventOfType:(NSInteger)type
{
    return [[self eventsOfType:type] count] > 0;
}


@end



@implementation ZincFunctionalTests

@synthesize repo = _repo;

//- (void)setUp
//{
//    [super setUp];
//
//    NSError* error = nil;
//    ZincRepo* repo = [ZincRepo zincRepoWithURL:[NSURL fileURLWithPath:TEST_RESOURCE_PATH(@"testrepo1")] error:&error];
//    if (repo == nil) {
//        STFail(@"%@", error);
//    }
//    self.repo = repo;
////    self.bundle.version = 1;
//}

- (void) testRepoLoadBasic
{
    
}

//- (void) testPathSimple
//{
//    NSString* path = [self.bundle pathForResource:@"a.txt"];
//    STAssertNotNil(path, @"path is nil");
//    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
//    STAssertTrue(exists, @"file does not exist");
//}

//- (void) testPathLessSimple
//{
//    NSString* path = [self.bundle pathForResource:@"1/b.txt"];
//    STAssertNotNil(path, @"path is nil");
//    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
//    STAssertTrue(exists, @"file does not exist");
//}

- (void) testBootstrappingBundle
{
    NSError* error = nil;

    NSString* repoDir = TEST_CREATE_TMP_DIR(@"repo");
    NSLog(@"%@", repoDir);
    NSURL* repoURL = [NSURL fileURLWithPath:repoDir];    
    ZincRepo* repo = [ZincRepo repoWithURL:repoURL error:&error];
    STAssertNotNil(repo, @"%@", error);
    
    NSString* bundleId = @"com.mindsnacks.demo1.sphalerites";
    
    repo.refreshInterval = 0;
    NSMutableArray* eventSink = [NSMutableArray array];
    repo.delegate = eventSink;
    
    [repo beginTrackingBundleWithId:bundleId
                       distribution:@"master" 
               bootstrapUsingBundle:[NSBundle bundleForClass:[self class]]];
    
    [repo resumeAllTasks];

    TEST_WAIT_UNTIL_TRUE([eventSink didReceiveEventOfType:ZincEventTypeBundleCloneComplete]);
    
    NSArray* receivedEvents = [eventSink eventsOfType:ZincEventTypeBundleCloneComplete];
    STAssertTrue([receivedEvents count] == 1, @"shoudl be 1 clone complete event");
    
    ZincBundleCloneCompleteEvent* event = (ZincBundleCloneCompleteEvent*)[receivedEvents objectAtIndex:0];
    NSURL* bundleRes = [NSURL zincResourceForBundleWithId:bundleId version:0];
    
    STAssertTrue([event.bundleResource isEqual:bundleRes], @"resource wrong");

    id bundle = [repo bundleWithId:bundleId];
    STAssertNotNil(bundle, @"bundle should not be nil");
}

- (void) testThatBootstrappingBundleOverwritesPreexistingBootstrappedBundle
{
    // set up a local repo with some files and a version 0 manifest
    // begin tracking a bundle, with the bootstrap option
    // it should overwrite any existing bootstrapped version
    
    NSError* error = nil;

    NSString* repoDir = TEST_CREATE_TMP_DIR(@"repo");
    NSLog(@"%@", repoDir);
    NSURL* repoURL = [NSURL fileURLWithPath:repoDir];    
    ZincRepo* repo = [ZincRepo repoWithURL:repoURL error:&error];
    STAssertNotNil(repo, @"%@", error);
    
    repo.refreshInterval = 0;
    NSMutableArray* eventSink = [NSMutableArray array];
    repo.delegate = eventSink;
    
    NSString* catalogId = @"com.mindsnacks.demo1";
    NSString* bundleId = @"sphalerites";
    
    // hack up the pre-existing bundle state
    
    // install a dummy manifest
    ZincManifest* oldManifest = [[[ZincManifest alloc] init] autorelease];
    oldManifest.catalogId = catalogId;
    oldManifest.bundleName = bundleId;
    oldManifest.version = 0;
    
    NSString* manifestPath = [repo pathForManifestWithBundleId:oldManifest.bundleName version:oldManifest.version];
    
    NSString* oldManifestJSON = [oldManifest jsonRepresentation:&error];
    if (oldManifestJSON == nil) {
        STFail(@"error: @%", error);
    }

    // register the bundle
    [repo registerBundle:[NSURL zincResourceForBundleWithId:bundleId version:0] status:ZincBundleStateAvailable];
    
    [repo beginTrackingBundleWithId:bundleId
                       distribution:@"master" 
               bootstrapUsingBundle:[NSBundle bundleForClass:[self class]]];
    
    [repo resumeAllTasks];
    
    TEST_WAIT_UNTIL_TRUE([eventSink didReceiveEventOfType:ZincEventTypeBundleCloneComplete]);
    
    NSString* newManifestJSON = [NSString stringWithContentsOfFile:manifestPath encoding:NSUTF8StringEncoding error:&error];
    STAssertNotNil(newManifestJSON, @"error: %@");
    
    STAssertFalse([oldManifestJSON isEqualToString:newManifestJSON], @"manifests should not be equal");
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

@end
