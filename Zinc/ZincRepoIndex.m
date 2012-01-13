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
@property (nonatomic, retain) NSMutableSet* myAvailableBundles;
@end

@implementation ZincRepoIndex

@synthesize mySourceURLs = _mySourceURLs;
@synthesize myTrackedBundles = _myTrackedBundles;
@synthesize myAvailableBundles = _myAvailableBundles;

- (id)init 
{
    self = [super init];
    if (self) {
        self.mySourceURLs = [NSMutableSet set];
        self.myTrackedBundles = [NSMutableDictionary dictionary];
        self.myAvailableBundles = [NSMutableSet set];
    }
    return self;
}

- (void)dealloc
{
    self.mySourceURLs = nil;
    self.myTrackedBundles = nil;
    self.myAvailableBundles = nil;
    [super dealloc];
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

- (void) addAvailableBundle:(NSURL*)bundleResouce
{
    @synchronized(self.myAvailableBundles) {
        [self.myAvailableBundles addObject:bundleResouce];
    }
}

- (void) removeAvailableBundle:(NSURL*)bundleResouce
{
    @synchronized(self.myAvailableBundles) {
        [self.myAvailableBundles removeObject:bundleResouce];
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
        
        NSDictionary* availBundles = [dict objectForKey:@"available_bundles"];
        self.myAvailableBundles = [NSMutableSet setWithCapacity:[availBundles count]];
        for (NSString* bundleId in [availBundles allKeys]) {
            NSArray* versions = [availBundles objectForKey:bundleId];
            for (NSNumber* version in versions) {
                NSURL* bundleRes = [NSURL zincResourceForBundleWithId:bundleId version:[version integerValue]];
                [self.myAvailableBundles addObject:bundleRes];
            }
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
        
    [dict setObject:self.myTrackedBundles forKey:@"tracked_bundles"];
    
    NSMutableDictionary* availBundles = [NSMutableDictionary dictionary];
    
    @synchronized(self.myAvailableBundles) {
        for (NSURL* bundleRes in self.myAvailableBundles) {
            
            NSMutableArray* versions = [availBundles objectForKey:[bundleRes zincBundleId]];
            if (versions == nil) {
                versions = [NSMutableArray array];
                [availBundles setObject:versions forKey:[bundleRes zincBundleId]];
            }
            [versions addObject:[NSNumber numberWithInteger:[bundleRes zincBundleVersion]]];
        }
    }
    
    [dict setObject:availBundles forKey:@"available_bundles"];
    
    return dict;
}

- (NSString*) jsonRepresentation:(NSError**)outError
{
    return [KSJSON serializeObject:[self dictionaryRepresentation] error:outError];
}


@end
