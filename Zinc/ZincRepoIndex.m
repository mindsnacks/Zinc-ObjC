//
//  ZincRepoIndex.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepoIndex.h"
#import "KSJSON.h"
#import "ZincResource.h"

@interface ZincRepoIndex ()
@property (nonatomic, retain) NSMutableSet* mySourceURLs;
@property (nonatomic, retain) NSMutableDictionary* myTrackedBundles;
@property (nonatomic, retain) NSMutableDictionary* myBundleStatus;
@end

@implementation ZincRepoIndex

@synthesize mySourceURLs = _mySourceURLs;
@synthesize myTrackedBundles = _myTrackedBundles;
@synthesize myBundleStatus = _myBundleStatus;

- (id)init 
{
    self = [super init];
    if (self) {
        self.mySourceURLs = [NSMutableSet set];
        self.myTrackedBundles = [NSMutableDictionary dictionary];
        self.myBundleStatus = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    self.mySourceURLs = nil;
    self.myTrackedBundles = nil;
    self.myBundleStatus = nil;
    [super dealloc];
}

- (BOOL) isEqual:(id)object
{
    if (self == object) return YES;
    
    if ([object class] != [self class]) return NO;
    
    ZincRepoIndex* other = (ZincRepoIndex*)object;
    
    if (![self.mySourceURLs isEqualToSet:other.mySourceURLs]) {
        return NO;
    }
    if (![self.myTrackedBundles isEqualToDictionary:other.myTrackedBundles]) {
        return NO;
    }
    if (![self.myBundleStatus isEqualToDictionary:other.myBundleStatus]) {
        return NO;
    }
    
    return YES;
}

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

- (void) setState:(ZincBundleState)state forBundle:(NSURL*)bundleResource
{
    @synchronized(self.myBundleStatus) {
        [self.myBundleStatus setObject:[NSNumber numberWithInteger:state] forKey:bundleResource];
    }
}

- (ZincBundleState) stateForBundle:(NSURL*)bundleResource
{
    @synchronized(self.myBundleStatus) {
        return [[self.myBundleStatus objectForKey:bundleResource] integerValue];
    }
}

- (void) removeBundle:(NSURL*)bundleResource
{
    @synchronized(self.myBundleStatus) {
        [self.myBundleStatus removeObjectForKey:bundleResource];
    }
}

- (NSSet*) availableBundles
{
    @synchronized(self.myBundleStatus) {
        return [self.myBundleStatus keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
            return [obj integerValue] == ZincBundleStateAvailable;
        }];
    }
}

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [self init];
    if (self) {

        NSArray* sourceURLs = [dict objectForKey:@"sources"];
        self.mySourceURLs = [NSMutableSet setWithCapacity:[sourceURLs count]];
        for (NSString* sourceURL in sourceURLs) {
            [self.mySourceURLs addObject:[NSURL URLWithString:sourceURL]];
        }
        
        self.myTrackedBundles = [[[dict objectForKey:@"tracked_bundles"] mutableCopy] autorelease];
        
        NSDictionary* bundleStatus = [dict objectForKey:@"bundle_status"];
        self.myBundleStatus = [NSMutableDictionary dictionaryWithCapacity:[bundleStatus count]];
        for (NSString* bundleResString in [bundleStatus allKeys]) {
            NSURL* bundleRes = [NSURL URLWithString:bundleResString];
            [self.myBundleStatus setObject:[bundleStatus objectForKey:bundleResString] forKey:bundleRes];
        }
    }
    return self;
}

- (NSDictionary*) dictionaryRepresentation
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];

    @synchronized(self.mySourceURLs) {
        NSMutableArray* sourceURLs = [NSMutableArray arrayWithCapacity:[self.mySourceURLs count]];
        for (NSURL* sourceURL in self.mySourceURLs) {
            [sourceURLs addObject:[sourceURL absoluteString]];
        }
        [dict setObject:sourceURLs forKey:@"sources"];
    }
        
    @synchronized(self.myTrackedBundles) {
        [dict setObject:[[self.myTrackedBundles copy] autorelease] forKey:@"tracked_bundles"];
    }
    
    NSMutableDictionary* bundleStatus = [NSMutableDictionary dictionary];
    
    @synchronized(self.myBundleStatus) {
        for (NSURL* bundleRes in self.myBundleStatus) {
            [bundleStatus setObject:[self.myBundleStatus objectForKey:bundleRes] forKey:[bundleRes absoluteString]];
        }
        [dict setObject:bundleStatus forKey:@"bundle_status"];
    }
    
    return dict;
}

- (NSString*) jsonRepresentation:(NSError**)outError
{
    return [KSJSON serializeObject:[self dictionaryRepresentation] error:outError];
}


@end
