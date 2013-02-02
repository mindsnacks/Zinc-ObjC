//
//  ZincRepoIndexTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/16/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepoIndexTests.h"
#import "ZincRepoIndex.h"
#import "ZincResource.h"
#import "ZincTrackingInfo.h"

@implementation ZincRepoIndexTests


- (void) _testDictionaryRoundtrip:(ZincRepoIndex*)index
{
    NSError* error = nil;
    NSDictionary* dict = [index dictionaryRepresentation];
    ZincRepoIndex* index2 = [ZincRepoIndex repoIndexFromDictionary:dict error:&error];
    STAssertEqualObjects(index, index2, @"objects should be equal");
}


- (void) testBasicEquality
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] init] autorelease];
    ZincRepoIndex* i2 = [[[ZincRepoIndex alloc] init] autorelease];
    
    STAssertEqualObjects(i1, i2, @"empty objects should be equal");
}

- (void) testAddSourceURL
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] init] autorelease];
    [i1 addSourceURL:[NSURL URLWithString:@"http://mindsnacks.com"]];
    
    BOOL contains = [[i1 sourceURLs] containsObject:[NSURL URLWithString:@"http://mindsnacks.com"]];
    STAssertTrue(contains, @"URL not found");
    
    [self _testDictionaryRoundtrip:i1];
}

- (void) testAddTrackedBundle
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] init] autorelease];
    ZincTrackingInfo* ref = [ZincTrackingInfo trackingInfoWithDistribution:@"prod" updateAutomatically:YES];
    [i1 setTrackingInfo:ref forBundleId:@"com.foo.bundle"];
    STAssertTrue([[i1 trackedDistributionForBundleId:@"com.foo.bundle"] isEqualToString:@"prod"], @"distro not found");
    
    [self _testDictionaryRoundtrip:i1];
}

- (void) testAvailableBundle
{
    NSURL* bundleRes = [NSURL zincResourceForBundleWithId:@"com.foo.bundle" version:1];
    
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] init] autorelease];
    [i1 setState:ZincBundleStateAvailable forBundle:bundleRes];
    
    BOOL contains = [[i1 availableBundles] containsObject:bundleRes];
    STAssertTrue(contains, @"URL not found");

    [self _testDictionaryRoundtrip:i1];
}

- (void) testUnavailableBundle
{
    NSURL* bundleRes = [NSURL zincResourceForBundleWithId:@"com.foo.bundle" version:1];
    
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] init] autorelease];
    [i1 setState:ZincBundleStateCloning forBundle:bundleRes];
    
    BOOL contains = [[i1 availableBundles] containsObject:bundleRes];
    STAssertFalse(contains, @"URL found");
    
    [self _testDictionaryRoundtrip:i1];
}

- (void) testSetBundleState
{
    NSURL* bundleRes = [NSURL zincResourceForBundleWithId:@"com.foo.bundle" version:1];
    
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] init] autorelease];
    [i1 setState:ZincBundleStateCloning forBundle:bundleRes];
    
    ZincBundleState state = [i1 stateForBundle:bundleRes];
    
    STAssertEquals(state, ZincBundleStateCloning, @"state is wrong");
    
    [self _testDictionaryRoundtrip:i1];
}

- (void) testReturnsNilTrackingRefIfBundleIsNotTracked
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] init] autorelease];
    ZincTrackingInfo* ref = [i1 trackingInfoForBundleId:@"foo.bundle"];
    STAssertNil(ref, @"tracking ref should be nil");
}

- (void) testValidFormat
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] init] autorelease];
    STAssertNoThrow(i1.format = 1, @"should not throw");
    STAssertEquals(i1.format, 1, @"should be 1");
}

- (void) testInvalidFormat
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] init] autorelease];
    STAssertThrows(i1.format = 0, @"should throw");
}

- (void) testDictionaryFormat1
{
    
}

- (void) testDictionaryFormat2
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] initWithFormat:2] autorelease];
    NSString* bundleID = @"com.foo.pants";
    ZincVersion version = 5;
    NSURL* bundleRes = [NSURL zincResourceForBundleWithId:bundleID version:version];
    [i1 setState:ZincBundleStateAvailable forBundle:bundleRes];
    
    NSDictionary* d = [i1 dictionaryRepresentation];
    NSDictionary* d_versions = d[@"bundles"][bundleID][@"versions"];
    
    id versionVal = d_versions[[[NSNumber numberWithInteger:version] stringValue]];
    
    STAssertEqualObjects(versionVal, ZincBundleStateName[ZincBundleStateAvailable], @"should be equal");
    
    
    NSLog(@"d");

}

@end
