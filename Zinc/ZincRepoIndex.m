//
//  ZincRepoIndex.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepoIndex.h"
#import "ZincJSONSerialization.h"
#import "ZincResource.h"
#import "ZincDeepCopying.h"
#import "ZincErrors.h"
#import "ZincTrackingRef.h"

@interface ZincRepoIndex ()
@property (nonatomic, retain) NSMutableSet* mySourceURLs;
@property (nonatomic, retain) NSMutableDictionary* myBundles;
@end


@implementation ZincRepoIndex

@synthesize mySourceURLs = _mySourceURLs;
@synthesize myBundles = _myBundles;

- (id)init 
{
    self = [super init];
    if (self) {
        self.mySourceURLs = [NSMutableSet set];
        self.myBundles = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    [_mySourceURLs release];
    [_myBundles release];
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
    if (![self.myBundles isEqualToDictionary:other.myBundles]) {
        return NO;
    }
    
    return YES;
}

- (void) addSourceURL:(NSURL*)url
{
    @synchronized(self.mySourceURLs) {
        [self.mySourceURLs addObject:url];
    }
}

- (NSSet*) sourceURLs
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

- (NSMutableDictionary*)bundleInfoDictForId:(NSString*)bundleId createIfMissing:(BOOL)create
{
    NSMutableDictionary* bundleInfo = [self.myBundles objectForKey:bundleId];
    if (bundleInfo == nil && create) {
        bundleInfo = [NSMutableDictionary dictionaryWithCapacity:2];
        [bundleInfo setObject:[NSMutableDictionary dictionaryWithCapacity:2] forKey:@"versions"];
        [self.myBundles setObject:bundleInfo forKey:bundleId];
    }
    return bundleInfo;
}

- (void) setTrackingRef:(ZincTrackingRef*)trackingRef forBundleId:(NSString*)bundleId
{
    @synchronized(self.myBundles) {
        NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleId createIfMissing:YES];
        NSDictionary* trackingRefDict = [trackingRef dictionaryRepresentation];
        [bundleInfo setObject:trackingRefDict forKey:@"tracking"];
    }    
}

- (void) removeTrackedBundleId:(NSString*)bundleId
{
    @synchronized(self.myBundles) {
        NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleId createIfMissing:NO];
        [bundleInfo removeObjectForKey:@"tracking"];
    }
}

- (NSSet*) trackedBundleIds
{
    NSMutableSet* set  = nil;
    @synchronized(self.myBundles) {
        set = [NSMutableSet setWithCapacity:[self.myBundles count]];
        NSArray* allBundleIds = [self.myBundles allKeys];
        for (NSString* bundleId in allBundleIds) {
            ZincTrackingRef* ref = [self trackingRefForBundleId:bundleId];
            if (ref != nil) {
                [set addObject:bundleId];
            }
        }
    }
    return set;
}

- (ZincTrackingRef*) trackingRefForBundleId:(NSString*)bundleId
{
    ZincTrackingRef* trackingRef = nil;
    @synchronized(self.myBundles) {
        id trackingRefObj = [[self.myBundles objectForKey:bundleId] objectForKey:@"tracking"];
        if ([trackingRefObj isKindOfClass:[NSString class]]) {
            // !!!: temporary kludge to read old style tracking refs
            trackingRef = [[[ZincTrackingRef alloc] init] autorelease];
            trackingRef.version = ZincVersionInvalid;
            trackingRef.distribution = trackingRefObj;
            trackingRef.updateAutomatically = YES; // all old tracking refs updated automatically
        } else if ([trackingRefObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary* trackingRefDict = (NSDictionary*)trackingRefObj;
            trackingRef = [ZincTrackingRef trackingRefFromDictionary:trackingRefDict];
        }
    }
    return trackingRef;
}

- (NSString*) trackedDistributionForBundleId:(NSString*)bundleId
{
    NSString* distro = nil;
    @synchronized(self.myBundles) {
        ZincTrackingRef* trackingRef = [self trackingRefForBundleId:bundleId];
        distro = trackingRef.distribution;
    }
    return distro;
}

- (void) setState:(ZincBundleState)state forBundle:(NSURL*)bundleResource
{
    @synchronized(self.myBundles) {
        NSString* bundleId = [bundleResource zincBundleId];
        ZincVersion bundleVersion = [bundleResource zincBundleVersion];
        NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleId createIfMissing:YES];
        NSMutableDictionary* versionInfo = [bundleInfo objectForKey:@"versions"];
        [versionInfo setObject:[NSNumber numberWithInteger:state] 
                        forKey:[[NSNumber numberWithInteger:bundleVersion] stringValue]];
    }
}

- (ZincBundleState) stateForBundle:(NSURL*)bundleResource
{
    ZincBundleState state = ZincBundleStateNone;
    @synchronized(self.myBundles) {
        NSString* bundleId = [bundleResource zincBundleId];
        ZincVersion bundleVersion = [bundleResource zincBundleVersion];
        NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleId createIfMissing:NO];
        NSMutableDictionary* versionInfo = [bundleInfo objectForKey:@"versions"];
        state = [[versionInfo objectForKey:[[NSNumber numberWithInteger:bundleVersion] stringValue]] integerValue];
    }
    return state;
}

- (void) removeBundle:(NSURL*)bundleResource
{
    @synchronized(self.myBundles) {
        NSString* bundleId = [bundleResource zincBundleId];
        ZincVersion bundleVersion = [bundleResource zincBundleVersion];
        NSDictionary* bundleInfo = [self bundleInfoDictForId:bundleId createIfMissing:NO];
        NSMutableDictionary* versionInfo = [bundleInfo objectForKey:@"versions"];
        [versionInfo removeObjectForKey:[[NSNumber numberWithInteger:bundleVersion] stringValue]];
    }
}

- (NSSet*) bundlesWithState:(ZincBundleState)targetState
{
    NSMutableSet* set = nil;
    @synchronized(self.myBundles) {
        set = [NSMutableSet set];
        NSArray* allBundleIds = [self.myBundles allKeys];
        for (NSString* bundleId in allBundleIds) {
            NSDictionary* bundleInfo = [self.myBundles objectForKey:bundleId];
            NSDictionary* versionInfo = [bundleInfo objectForKey:@"versions"];
            NSArray* allVersions = [versionInfo allKeys];
            for (NSNumber* version in allVersions) {
                ZincBundleState state = [[versionInfo objectForKey:version] integerValue];
                if (state == targetState) {
                    [set addObject:[NSURL zincResourceForBundleWithId:bundleId version:[version integerValue]]];
                }
            }
        }
    }
    return set;
}

- (NSSet*) availableBundles
{
    return [self bundlesWithState:ZincBundleStateAvailable];
}

- (NSSet*) cloningBundles
{
    return [self bundlesWithState:ZincBundleStateCloning];
}

- (NSArray*) availableVersionsForBundleId:(NSString*)bundleId
{
    NSMutableArray* versions = [NSMutableArray arrayWithCapacity:5];
    NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleId createIfMissing:NO];
    NSMutableDictionary* versionInfo = [bundleInfo objectForKey:@"versions"];

    [versionInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj integerValue] == ZincBundleStateAvailable) {
            NSInteger version = [key integerValue];
            [versions addObject:[NSNumber numberWithInteger:version]];
        }
    }];
    
    return [versions sortedArrayUsingSelector:@selector(compare:)];
}

- (ZincVersion) newestAvailableVersionForBundleId:(NSString*)bundleId
{
    NSNumber* version = [[self availableVersionsForBundleId:bundleId] lastObject];
    if (version != nil) {
        return [version integerValue];
    }
    return ZincVersionInvalid;
}

+ (id) repoIndexFromDictionary:(NSDictionary*)dict error:(NSError**)outError
{
    int format = [[dict objectForKey:@"format"] intValue];
    if (format != 1) {
        if (outError != NULL) {
            *outError = ZincError(ZINC_ERR_INVALID_REPO_FORMAT);
        }
        [self autorelease];
        return nil;
    }
    
    ZincRepoIndex* index = [[[ZincRepoIndex alloc] init] autorelease];
    
    NSArray* sourceURLs = [dict objectForKey:@"sources"];
    index.mySourceURLs = [NSMutableSet setWithCapacity:[sourceURLs count]];
    for (NSString* sourceURL in sourceURLs) {
        [index.mySourceURLs addObject:[NSURL URLWithString:sourceURL]];
    }
    
    NSMutableDictionary* bundles = [dict objectForKey:@"bundles"];
    if (bundles != nil) {
        bundles = [bundles zinc_deepMutableCopy];
    } else {
        bundles = [NSMutableDictionary dictionary];
    }
    index.myBundles = bundles;
    
    return index;
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
        
    @synchronized(self.myBundles) {
        [dict setObject:[self.myBundles zinc_deepCopy] forKey:@"bundles"];
    }
    [dict setObject:[NSNumber numberWithInt:1] forKey:@"format"];
    
    return dict;
}

- (NSData*) jsonRepresentation:(NSError**)outError
{
    return [NSJSONSerialization dataWithJSONObject:[self dictionaryRepresentation] options:0 error:outError];
}


@end
