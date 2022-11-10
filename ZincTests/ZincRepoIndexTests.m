//
//  ZincRepoIndexTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/16/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepoIndex.h"
#import "ZincResource.h"
#import "ZincTrackingInfo.h"


@interface ZincRepoIndexTests : XCTestCase

@property (nonatomic) NSURL *url;

@end


@implementation ZincRepoIndexTests


- (void) _testDictionaryRoundtrip:(ZincRepoIndex*)index
{
    NSError* error = nil;
    NSDictionary* dict = [index dictionaryRepresentation];
    ZincRepoIndex* index2 = [ZincRepoIndex repoIndexFromDictionary:dict fileURL:url error:&error];
    XCTAssertEqualObjects(index, index2, @"objects should be equal");
}


- (void) testBasicEquality
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] initWithFileURL:url] autorelease];
    ZincRepoIndex* i2 = [[[ZincRepoIndex alloc] initWithFileURL:url] autorelease];
    
    XCTAssertEqualObjects(i1, i2, @"empty objects should be equal");
}

- (void) testAddSourceURL
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] initWithFileURL:url] autorelease];
    [i1 addSourceURL:[NSURL URLWithString:@"http://mindsnacks.com"]];
    
    BOOL contains = [[i1 sourceURLs] containsObject:[NSURL URLWithString:@"http://mindsnacks.com"]];
    XCTAssertTrue(contains, @"URL not found");
    
    [self _testDictionaryRoundtrip:i1];
}

- (void) testAddTrackedBundle
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] initWithFileURL:url] autorelease];
    ZincTrackingInfo* ref = [ZincTrackingInfo trackingInfoWithDistribution:@"prod"];
    [i1 setTrackingInfo:ref forBundleID:@"com.foo.bundle"];
    XCTAssertTrue([[i1 trackedDistributionForBundleID:@"com.foo.bundle"] isEqualToString:@"prod"], @"distro not found");
    
    [self _testDictionaryRoundtrip:i1];
}

- (void) testAvailableBundle
{
    NSURL* bundleRes = [NSURL zincResourceForBundleWithID:@"com.foo.bundle" version:1];
    
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] initWithFileURL:url] autorelease];
    [i1 setState:ZincBundleStateAvailable forBundle:bundleRes];
    
    BOOL contains = [[i1 availableBundles] containsObject:bundleRes];
    XCTAssertTrue(contains, @"URL not found");

    [self _testDictionaryRoundtrip:i1];
}

- (void) testUnavailableBundle
{
    NSURL* bundleRes = [NSURL zincResourceForBundleWithID:@"com.foo.bundle" version:1];
    
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] initWithFileURL:url] autorelease];
    [i1 setState:ZincBundleStateCloning forBundle:bundleRes];
    
    BOOL contains = [[i1 availableBundles] containsObject:bundleRes];
    XCTAssertFalse(contains, @"URL found");
    
    [self _testDictionaryRoundtrip:i1];
}

- (void) testSetBundleState
{
    NSURL* bundleRes = [NSURL zincResourceForBundleWithID:@"com.foo.bundle" version:1];
    
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] initWithFileURL:url] autorelease];
    [i1 setState:ZincBundleStateCloning forBundle:bundleRes];
    
    ZincBundleState state = [i1 stateForBundle:bundleRes];
    
    XCTAssertEqual(state, ZincBundleStateCloning, @"state is wrong");
    
    [self _testDictionaryRoundtrip:i1];
}

- (void) testReturnsNilTrackingRefIfBundleIsNotTracked
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] initWithFileURL:url] autorelease];
    ZincTrackingInfo* ref = [i1 trackingInfoForBundleID:@"foo.bundle"];
    XCTAssertNil(ref, @"tracking ref should be nil");
}

- (void) testValidFormat
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] initWithFileURL:url] autorelease];
    XCTAssertNoThrow(i1.format = 1, @"should not throw");
    XCTAssertEqual(i1.format, (NSInteger)1, @"should be 1");
}

- (void) testInvalidFormat
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] initWithFileURL:url] autorelease];
    XCTAssertThrows(i1.format = 0, @"should throw");
}

- (void) testDictionaryFormat1
{
    
}

- (void) testDictionaryFormat2
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] initWithFormat:2 fileURL:url] autorelease];
    NSString* bundleID = @"com.foo.pants";
    ZincVersion version = 5;
    NSURL* bundleRes = [NSURL zincResourceForBundleWithID:bundleID version:version];
    [i1 setState:ZincBundleStateAvailable forBundle:bundleRes];
    
    NSDictionary* d = [i1 dictionaryRepresentation];
    NSDictionary* d_versions = d[@"bundles"][bundleID][@"versions"];
    
    id versionVal = d_versions[[[NSNumber numberWithInteger:version] stringValue]];
    
    XCTAssertEqualObjects(versionVal, ZincBundleStateName[ZincBundleStateAvailable], @"should be equal");
    
    
    NSLog(@"d");

}

@end
