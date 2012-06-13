//
//  ZincRepoIndex.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepoIndex.h"
#import "ZincKSJSON.h"
#import "ZincResource.h"
#import "ZincDeepCopying.h"
#import "ZincErrors.h"

@interface ZincRepoIndex ()
@property (nonatomic, retain) NSMutableSet* mySourceURLs;
@property (nonatomic, retain) NSMutableDictionary* myBundles;
@property (nonatomic, retain) NSMutableSet* myLocalBundles;
@end


@implementation ZincRepoIndex

@synthesize mySourceURLs = _mySourceURLs;
@synthesize myBundles = _myBundles;
@synthesize myLocalBundles = _myLocalBundles;

- (id)init 
{
    self = [super init];
    if (self) {
        self.mySourceURLs = [NSMutableSet set];
        self.myBundles = [NSMutableDictionary dictionary];
        self.myLocalBundles = [NSMutableSet set];
    }
    return self;
}

- (void)dealloc
{
    self.mySourceURLs = nil;
    self.myBundles = nil;
    self.myLocalBundles = nil;
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
    if (![self.myLocalBundles isEqualToSet:other.myLocalBundles]) {
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

- (void) addTrackedBundleId:(NSString*)bundleId distribution:(NSString*)distro
{
    @synchronized(self.myBundles) {
        NSMutableDictionary* bundleInfo = [self bundleInfoDictForId:bundleId createIfMissing:YES];
        [bundleInfo setObject:distro forKey:@"tracking"];
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
            NSString* distro = [self trackedDistributionForBundleId:bundleId];
            if (distro != nil) {
                [set addObject:bundleId];
            }
        }
    }
    return set;
}

- (NSString*) trackedDistributionForBundleId:(NSString*)bundleId
{
    NSString* distro = nil;
    @synchronized(self.myBundles) {
        distro = [[self.myBundles objectForKey:bundleId] objectForKey:@"tracking"];
    }
    return distro;
}

- (void) addLocalBundle:(NSURL*)bundleResource
{
    @synchronized(self.myLocalBundles) {
        [self.myLocalBundles addObject:bundleResource];
    }
}

- (NSSet*) localBundles
{
    NSSet* localBundles = nil;
    @synchronized(self.myLocalBundles) {
        localBundles = [NSSet setWithSet:self.myLocalBundles];
    }
    return localBundles;
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
    
    NSArray* localBundles = [dict objectForKey:@"localbundles"];
    index.myLocalBundles = [NSMutableSet setWithCapacity:[localBundles count]];
    for (NSString* localBundleRes in localBundles) {
        [index.myLocalBundles addObject:[NSURL URLWithString:localBundleRes]];
    }
    
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
    
    @synchronized(self.myLocalBundles) {
        NSMutableArray* localBundleRes = [NSMutableArray arrayWithCapacity:[self.myLocalBundles count]];
        for (NSURL* sourceURL in self.myLocalBundles) {
            [localBundleRes addObject:[sourceURL absoluteString]];
        }
        [dict setObject:localBundleRes forKey:@"localbundles"];
    }

    return dict;
}

- (NSString*) jsonRepresentation:(NSError**)outError
{
    return [ZincKSJSON serializeObject:[self dictionaryRepresentation] error:outError];
}


@end
