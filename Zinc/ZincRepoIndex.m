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
#import "ZincTrackingInfo.h"
#import "ZincExternalBundleInfo.h"

@interface ZincRepoIndex ()
@property (nonatomic, retain) NSMutableSet* mySourceURLs;
@property (nonatomic, retain) NSMutableDictionary* myBundles;
@property (nonatomic, retain) NSMutableDictionary* myExternalBundlesByResource;
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
        self.myExternalBundlesByResource = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    [_mySourceURLs release];
    [_myBundles release];
    [_myExternalBundlesByResource release];
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

- (void) setTrackingInfo:(ZincTrackingInfo*)trackingInfo forBundleId:(NSString*)bundleId
{
    @synchronized(self.myBundles) {
        NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleId createIfMissing:YES];
        NSDictionary* trackingInfoDict = [trackingInfo dictionaryRepresentation];
        [bundleInfo setObject:trackingInfoDict forKey:@"tracking"];
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
            ZincTrackingInfo* trackingInfo = [self trackingInfoForBundleId:bundleId];
            if (trackingInfo != nil) {
                [set addObject:bundleId];
            }
        }
    }
    return set;
}

- (ZincTrackingInfo*) trackingInfoForBundleId:(NSString*)bundleId
{
    ZincTrackingInfo* trackingInfo = nil;
    @synchronized(self.myBundles) {
        id trackingInfoObj = [[self.myBundles objectForKey:bundleId] objectForKey:@"tracking"];
        if ([trackingInfoObj isKindOfClass:[NSString class]]) {
            // !!!: temporary kludge to read old style tracking infos
            trackingInfo = [[[ZincTrackingInfo alloc] init] autorelease];
            trackingInfo.version = ZincVersionInvalid;
            trackingInfo.distribution = trackingInfoObj;
            trackingInfo.updateAutomatically = YES; // all old tracking infos updated automatically
        } else if ([trackingInfoObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary* trackingInfoDict = (NSDictionary*)trackingInfoObj;
            trackingInfo = [ZincTrackingInfo trackingInfoFromDictionary:trackingInfoDict];
        }
    }
    return trackingInfo;
}

- (NSString*) trackedDistributionForBundleId:(NSString*)bundleId
{
    NSString* distro = nil;
    @synchronized(self.myBundles) {
        ZincTrackingInfo* trackingInfo = [self trackingInfoForBundleId:bundleId];
        distro = trackingInfo.distribution;
    }
    return distro;
}

- (NSString*) trackedFlavorForBundleId:(NSString*)bundleId
{
    NSString* flavor = nil;
    @synchronized(self.myBundles) {
        ZincTrackingInfo* trackingInfo = [self trackingInfoForBundleId:bundleId];
        flavor = trackingInfo.flavor;
    }
    return flavor;
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
    @synchronized(self.myExternalBundlesByResource) {
        ZincExternalBundleInfo* info = self.myExternalBundlesByResource[bundleResource];
        if (info != nil) {
            return ZincBundleStateAvailable;
        }
    }
    @synchronized(self.myBundles) {
        NSString* bundleId = [bundleResource zincBundleId];
        ZincVersion bundleVersion = [bundleResource zincBundleVersion];
        NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleId createIfMissing:NO];
        NSMutableDictionary* versionInfo = [bundleInfo objectForKey:@"versions"];
        ZincBundleState state = [[versionInfo objectForKey:[[NSNumber numberWithInteger:bundleVersion] stringValue]] integerValue];
        return state;
    }
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

- (void) registerExternalBundle:(NSURL*)bundleRes manifestPath:(NSString*)manifestPath bundleRootPath:(NSString*)rootPath
{
    @synchronized(self.myExternalBundlesByResource) {
        ZincExternalBundleInfo* info = [ZincExternalBundleInfo infoForBundleResource:bundleRes manifestPath:manifestPath bundleRootPath:rootPath];
        self.myExternalBundlesByResource[bundleRes] = info;
    }
}

- (ZincExternalBundleInfo*) infoForExternalBundle:(NSURL*)bundleRes
{
    @synchronized(self.myExternalBundlesByResource) {
        ZincExternalBundleInfo* info = self.myExternalBundlesByResource[bundleRes];
        return info;
    }
}

- (NSArray*) registeredExternalBundles
{
    @synchronized(self.myExternalBundlesByResource) {
        return [self.myExternalBundlesByResource allKeys];
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
    if (targetState == ZincBundleStateAvailable) {
        @synchronized(self.myExternalBundlesByResource) {
            [set addObjectsFromArray:[self.myExternalBundlesByResource allKeys]];
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
    
    @synchronized(self.myExternalBundlesByResource) {
        [self.myExternalBundlesByResource enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSURL* bundleRes = key;
            if ([[bundleRes zincBundleId] isEqualToString:bundleId]) {
                [versions addObject:[NSNumber numberWithInteger:[bundleRes zincBundleVersion]]];
            }
        }];
    }
    
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
