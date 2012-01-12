//
//  ZincRepoIndex.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepoIndex.h"

@interface ZincRepoIndex ()
@property (nonatomic, retain) NSMutableSet* mySourceURLs;
@property (nonatomic, retain) NSMutableDictionary* myTrackedBundles;
@property (nonatomic, retain) NSMutableSet* myAvailableBundles;
@end

@implementation ZincRepoIndex

@synthesize mySourceURLs = _mySourceURLs;
@synthesize myTrackedBundles = _myTrackedBundles;
@synthesize myAvailableBundles = _myAvailableBundles;

- (void) addSourceURL:(NSURL*)url
{
    @synchronized(self.sourceURLS) {
        [self.mySourceURLs addObject:url];
    }
}

- (NSSet*) sourceURLS
{
    NSSet* urls = nil;
    @synchronized(self.mySourceURLs) {
       urls = [NSSet setWithSet:self.mySourceURLs];
    }
    return urls;
}

- (void) removeSourceURL:(NSURL*)url
{
    @synchronized(self.mySourceURLs) {
        [self.mySourceURLs removeObject:url];
    }
}

- (void) addTrackedBundleId:(NSString*)bundleId distribution:(NSString*)distro
{
    @synchronized(self.myTrackedBundles) {
        [self.myTrackedBundles setObject:distro forKey:bundleId];
    }
}

- (void) removeTrackedBundleId:(NSString*)bundleId
{
    @synchronized(self.myTrackedBundles) {
        [self.myTrackedBundles removeObjectForKey:bundleId];
    }
}

- (NSSet*) trackedBundleIds
{
    NSSet* set = nil;
    @synchronized(self.myTrackedBundles) {
        set = [NSSet setWithArray:[self.myTrackedBundles allKeys]];
    }
    return set;
}

- (NSString*) trackedDistributionForBundleId:(NSString*)bundleId
{
    NSString* key = nil;
    @synchronized(self.myTrackedBundles) {
        key = [self.myTrackedBundles objectForKey:bundleId];
    }
    return key;
}

- (void) addAvailableBundle:(ZincBundleDescriptor*)bundleDesc
{
    @synchronized(self.myAvailableBundles) {
        [self.myAvailableBundles addObject:bundleDesc];
    }
}

- (void) removeAvailableBundle:(ZincBundleDescriptor*)bundleDesc
{
    @synchronized(self.myAvailableBundles) {
        [self.myAvailableBundles removeObject:bundleDesc];
    }
}

- (NSSet*) availableBundles
{
    NSSet* set = nil;
    @synchronized(self.myAvailableBundles) {
        set = [NSSet setWithSet:self.myAvailableBundles];
    }
    return set;
}

//- (id) initWithDictionary:(NSDictionary*)dict;
//- (NSDictionary*) dictionaryRepresentation;
//- (NSString*) jsonRepresentation:(NSError**)outError;


@end
