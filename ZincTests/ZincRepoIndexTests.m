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

@implementation ZincRepoIndexTests


- (void) _testDictionaryRoundtrip:(ZincRepoIndex*)index
{
    NSDictionary* dict = [index dictionaryRepresentation];
    ZincRepoIndex* index2 = [[[ZincRepoIndex alloc] initWithDictionary:dict] autorelease];
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
    
    BOOL contains = [[i1 sourceURLS] containsObject:[NSURL URLWithString:@"http://mindsnacks.com"]];
    STAssertTrue(contains, @"URL not found");
    
    [self _testDictionaryRoundtrip:i1];
}

- (void) testAddTrackedBundle
{
    ZincRepoIndex* i1 = [[[ZincRepoIndex alloc] init] autorelease];
    [i1 addTrackedBundleId:@"com.foo.bundle" distribution:@"prod"];
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

@end
