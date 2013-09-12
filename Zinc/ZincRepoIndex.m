//
//  ZincRepoIndex.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepoIndex.h"

#import "ZincInternals.h"
#import "ZincExternalBundleInfo.h"


@interface ZincRepoIndex ()
@property (nonatomic, strong) NSMutableSet* mySourceURLs;
@property (nonatomic, strong) NSMutableDictionary* myBundles;
@property (nonatomic, strong) NSMutableDictionary* myExternalBundlesByResource;
@end


@implementation ZincRepoIndex

- (id) init
{
    return [self initWithFormat:kZincRepoIndexCurrentFormat];
}

- (id)initWithFormat:(NSInteger)format
{
    self = [super init];
    if (self) {
        self.format = format;
        self.mySourceURLs = [NSMutableSet set];
        self.myBundles = [NSMutableDictionary dictionary];
        self.myExternalBundlesByResource = [NSMutableDictionary dictionary];
    }
    return self;
}


+ (NSSet*) validFormats
{
    return [NSSet setWithArray:@[@1, @2]];
}

- (void) setFormat:(NSInteger)format
{
    if (![[[self class] validFormats] containsObject:@(format)]) {
        @throw [NSException
                exceptionWithName:NSInternalInconsistencyException
                reason:[NSString stringWithFormat:@"Invalid format version"]
                userInfo:nil];
    }
    _format = format;
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

- (NSMutableDictionary*)bundleInfoDictForId:(NSString*)bundleID createIfMissing:(BOOL)create
{
    NSMutableDictionary* bundleInfo = nil;
    @synchronized(self.myBundles) {
        bundleInfo = (self.myBundles)[bundleID];
        if (bundleInfo == nil && create) {
            bundleInfo = [NSMutableDictionary dictionaryWithCapacity:2];
            bundleInfo[@"versions"] = [NSMutableDictionary dictionaryWithCapacity:2];
            (self.myBundles)[bundleID] = bundleInfo;
        }
    }
    return bundleInfo;
}

- (void) setTrackingInfo:(ZincTrackingInfo*)trackingInfo forBundleID:(NSString*)bundleID
{
    @synchronized(self.myBundles) {
        NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleID createIfMissing:YES];
        NSDictionary* trackingInfoDict = [trackingInfo dictionaryRepresentation];
        bundleInfo[@"tracking"] = trackingInfoDict;
    }    
}

- (void) removeTrackedBundleID:(NSString*)bundleID
{
    @synchronized(self.myBundles) {
        NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleID createIfMissing:NO];
        [bundleInfo removeObjectForKey:@"tracking"];
    }
}

- (NSSet*) trackedBundleIDs
{
    NSMutableSet* set  = nil;
    @synchronized(self.myBundles) {
        set = [NSMutableSet setWithCapacity:[self.myBundles count]];
        NSArray* allBundleIDs = [self.myBundles allKeys];
        for (NSString* bundleID in allBundleIDs) {
            ZincTrackingInfo* trackingInfo = [self trackingInfoForBundleID:bundleID];
            if (trackingInfo != nil) {
                [set addObject:bundleID];
            }
        }
    }
    return set;
}

- (ZincTrackingInfo*) trackingInfoForBundleID:(NSString*)bundleID
{
    ZincTrackingInfo* trackingInfo = nil;
    @synchronized(self.myBundles) {
        id trackingInfoObj = (self.myBundles)[bundleID][@"tracking"];
        if ([trackingInfoObj isKindOfClass:[NSString class]]) {
            // !!!: temporary kludge to read old style tracking infos
            trackingInfo = [[ZincTrackingInfo alloc] init];
            trackingInfo.version = ZincVersionInvalid;
            trackingInfo.distribution = trackingInfoObj;
        } else if ([trackingInfoObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary* trackingInfoDict = (NSDictionary*)trackingInfoObj;
            trackingInfo = [ZincTrackingInfo trackingInfoFromDictionary:trackingInfoDict];
        }
    }
    return trackingInfo;
}

- (NSString*) trackedDistributionForBundleID:(NSString*)bundleID
{
    NSString* distro = nil;
    @synchronized(self.myBundles) {
        ZincTrackingInfo* trackingInfo = [self trackingInfoForBundleID:bundleID];
        distro = trackingInfo.distribution;
    }
    return distro;
}

- (NSString*) trackedFlavorForBundleID:(NSString*)bundleID
{
    NSString* flavor = nil;
    @synchronized(self.myBundles) {
        ZincTrackingInfo* trackingInfo = [self trackingInfoForBundleID:bundleID];
        flavor = trackingInfo.flavor;
    }
    return flavor;
}

- (void) setState:(ZincBundleState)state forBundle:(NSURL*)bundleResource
{
    @synchronized(self.myBundles) {
        NSString* bundleID = [bundleResource zincBundleID];
        ZincVersion bundleVersion = [bundleResource zincBundleVersion];
        NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleID createIfMissing:YES];
        NSMutableDictionary* versionInfo = bundleInfo[@"versions"];
        NSString* versionKey = [@(bundleVersion) stringValue];
        if (state == ZincBundleStateNone) {
            [versionInfo removeObjectForKey:versionKey];
        } else {
            versionInfo[versionKey] = @(state);
        }
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
        NSString* bundleID = [bundleResource zincBundleID];
        ZincVersion bundleVersion = [bundleResource zincBundleVersion];
        NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleID createIfMissing:NO];
        NSMutableDictionary* versionInfo = bundleInfo[@"versions"];
        ZincBundleState state = [versionInfo[[@(bundleVersion) stringValue]] integerValue];
        return state;
    }
}

- (void) removeBundle:(NSURL*)bundleResource
{
    @synchronized(self.myBundles) {
        NSString* bundleID = [bundleResource zincBundleID];
        ZincVersion bundleVersion = [bundleResource zincBundleVersion];
        NSDictionary* bundleInfo = [self bundleInfoDictForId:bundleID createIfMissing:NO];
        NSMutableDictionary* versionInfo = bundleInfo[@"versions"];
        [versionInfo removeObjectForKey:[@(bundleVersion) stringValue]];
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
        NSArray* allBundleIDs = [self.myBundles allKeys];
        for (NSString* bundleID in allBundleIDs) {
            NSDictionary* bundleInfo = (self.myBundles)[bundleID];
            NSDictionary* versionInfo = bundleInfo[@"versions"];
            NSArray* allVersions = [versionInfo allKeys];
            for (NSNumber* version in allVersions) {
                ZincBundleState state = [versionInfo[version] integerValue];
                if (state == targetState) {
                    [set addObject:[NSURL zincResourceForBundleWithID:bundleID version:[version integerValue]]];
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

- (NSArray*) availableVersionsForBundleID:(NSString*)bundleID
{
    NSMutableArray* versions = [NSMutableArray arrayWithCapacity:5];
    NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleID createIfMissing:NO];
    NSMutableDictionary* versionInfo = bundleInfo[@"versions"];

    [versionInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj integerValue] == ZincBundleStateAvailable) {
            NSInteger version = [key integerValue];
            [versions addObject:@(version)];
        }
    }];
    
    @synchronized(self.myExternalBundlesByResource) {
        [self.myExternalBundlesByResource enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSURL* bundleRes = key;
            if ([[bundleRes zincBundleID] isEqualToString:bundleID]) {
                [versions addObject:@([bundleRes zincBundleVersion])];
            }
        }];
    }
    
    return [versions sortedArrayUsingSelector:@selector(compare:)];
}

+ (id) repoIndexFromDictionary_1:(NSDictionary*)dict
{
    ZincRepoIndex* index = [[ZincRepoIndex alloc] initWithFormat:1];
    
    NSArray* sourceURLs = dict[@"sources"];
    index.mySourceURLs = [NSMutableSet setWithCapacity:[sourceURLs count]];
    for (NSString* sourceURL in sourceURLs) {
        [index.mySourceURLs addObject:[NSURL URLWithString:sourceURL]];
    }
    
    NSMutableDictionary* bundles = dict[@"bundles"];
    if (bundles != nil) {
        bundles = [bundles zinc_deepMutableCopy];
    } else {
        bundles = [NSMutableDictionary dictionary];
    }
    index.myBundles = bundles;
    
    return index;
}

+ (id) repoIndexFromDictionary_2:(NSDictionary*)dict
{
    ZincRepoIndex* index = [[ZincRepoIndex alloc] initWithFormat:2];
    
    NSArray* sourceURLs = dict[@"sources"];
    index.mySourceURLs = [NSMutableSet setWithCapacity:[sourceURLs count]];
    for (NSString* sourceURL in sourceURLs) {
        [index.mySourceURLs addObject:[NSURL URLWithString:sourceURL]];
    }
    
    NSMutableDictionary* bundles = dict[@"bundles"];
    if (bundles != nil) {
        bundles = [bundles zinc_deepMutableCopy];
        
        // Translate bundle state from human-readable name
        NSArray* bundleKeys = [bundles allKeys];
        for (NSString* bundleID in bundleKeys) {
            NSMutableDictionary* bundleInfo = bundles[bundleID];
            NSMutableDictionary* versionInfo = bundleInfo[@"versions"];
            NSArray* versionKeys = [versionInfo allKeys];
            for (NSString* versionKey in versionKeys) {
                NSString* name = versionInfo[versionKey];
                ZincBundleState state = ZincBundleStateFromName(name);
                versionInfo[versionKey] = @(state);
            }
        }
    } else {
        bundles = [NSMutableDictionary dictionary];
    }
    index.myBundles = bundles;
    
    return index;
}

+ (id) repoIndexFromDictionary:(NSDictionary*)dict error:(NSError**)outError
{
    NSInteger format = [dict[@"format"] intValue];
    if (![[[self class] validFormats] containsObject:@(format)]) {
        if (outError != NULL) {
            *outError = ZincError(ZINC_ERR_INVALID_REPO_FORMAT);
        }
        return nil;
    }
    
    if (format == 1) {
        return [self repoIndexFromDictionary_1:dict];
    } else if (format == 2) {
        return [self repoIndexFromDictionary_2:dict];
    }
    
    NSAssert(NO, @"unknown format");
    return nil;
}

- (NSDictionary*) dictionaryRepresentation_1
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];

    @synchronized(self.mySourceURLs) {
        NSMutableArray* sourceURLs = [NSMutableArray arrayWithCapacity:[self.mySourceURLs count]];
        for (NSURL* sourceURL in self.mySourceURLs) {
            [sourceURLs addObject:[sourceURL absoluteString]];
        }
        dict[@"sources"] = sourceURLs;
    }
        
    @synchronized(self.myBundles) {
        dict[@"bundles"] = [self.myBundles zinc_deepCopy];
    }
    
    dict[@"format"] = @(self.format);
    
    return dict;
}

- (NSDictionary*) dictionaryRepresentation_2
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    @synchronized(self.mySourceURLs) {
        NSMutableArray* sourceURLs = [NSMutableArray arrayWithCapacity:[self.mySourceURLs count]];
        for (NSURL* sourceURL in self.mySourceURLs) {
            [sourceURLs addObject:[sourceURL absoluteString]];
        }
        dict[@"sources"] = sourceURLs;
    }
    
    NSMutableDictionary* bundles;
    @synchronized(self.myBundles) {
        bundles = [self.myBundles zinc_deepMutableCopy] ;
    }

    // Translate bundle state into human-readable name
    NSArray* bundleKeys = [bundles allKeys];
    for (NSString* bundleID in bundleKeys) {
        NSMutableDictionary* bundleInfo = bundles[bundleID];
        NSMutableDictionary* versionInfo = bundleInfo[@"versions"];
        NSArray* versionKeys = [versionInfo allKeys];
        for (NSString* versionKey in versionKeys) {
            ZincBundleState state = [versionInfo[versionKey] integerValue];
            versionInfo[versionKey] = ZincBundleStateName[state];
        }
    }
    dict[@"bundles"] = bundles;
    
    dict[@"format"] = @(self.format);
    
    return dict;
}

- (NSDictionary*) dictionaryRepresentation
{
    if (self.format == 1) {
        return [self dictionaryRepresentation_1];
    } else if (self.format == 2) {
        return [self dictionaryRepresentation_2];
    }
    @throw [NSException
            exceptionWithName:NSInternalInconsistencyException
            reason:[NSString stringWithFormat:@"Invalid format version"]
            userInfo:nil];
}

@end
