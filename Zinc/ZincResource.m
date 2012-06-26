//
//  ZincResourceDescriptor.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincResource.h"
#import "ZincUtils.h"

#define ZINC_RESOURCE_SCHEME @"zincresource"

@implementation NSURL (ZincResource)

- (BOOL) isZincResourceOfType:(NSString*)type
{
    if (![[self scheme] isEqualToString:ZINC_RESOURCE_SCHEME]) {
        return NO;
    }
    if (![[self host] isEqualToString:type]) {
        return NO;
    }
    return YES;
}

+ (NSURL*) zincResourceForCatalogWithId:(NSString*)catalogId
{
    NSString* path = [@"/" stringByAppendingString:catalogId];
   return [[[NSURL alloc] initWithScheme:ZINC_RESOURCE_SCHEME host:@"catalog" path:path] autorelease];
}

- (BOOL) isZincCatalogResource
{
    return [self isZincResourceOfType:@"catalog"];
}

- (NSString*) zincCatalogId
{
    if ([self isZincCatalogResource]) {
        return [[self path] substringFromIndex:1];
        
    } else if ([self isZincBundleResource]) {
        return ZincCatalogIdFromBundleId([self zincBundleId]);

    } else if ([self isZincObjectResource]) {
        NSString* catalogId = [self path];
        catalogId = [catalogId stringByDeletingLastPathComponent]; // strip version
        catalogId = [catalogId substringFromIndex:1]; // strip leading /
        return catalogId;
    }
    
    return nil;
}

+ (NSURL*) zincResourceForManifestWithId:(NSString*)bundleId version:(ZincVersion)version
{
    NSString* path = [NSString stringWithFormat:@"/%@/%d", bundleId, version];
    return [[[NSURL alloc] initWithScheme:ZINC_RESOURCE_SCHEME host:@"manifest" path:path] autorelease];
}

- (BOOL) isZincManifestResource
{
    return [self isZincResourceOfType:@"manifest"];
}

+ (NSURL*) zincResourceForBundleWithId:(NSString*)bundleId version:(ZincVersion)version
{
    NSString* path = [NSString stringWithFormat:@"/%@/%d", bundleId, version];
    return [[[NSURL alloc] initWithScheme:ZINC_RESOURCE_SCHEME host:@"bundle" path:path] autorelease];
}

- (BOOL) isZincBundleResource
{
    return [self isZincResourceOfType:@"bundle"];
}

+ (NSURL*) zincResourceForArchiveWithId:(NSString*)bundleId version:(ZincVersion)version
{
    NSString* path = [NSString stringWithFormat:@"/%@/%d", bundleId, version];
    return [[[NSURL alloc] initWithScheme:ZINC_RESOURCE_SCHEME host:@"archive" path:path] autorelease];
}

- (BOOL) isZincArchiveResource
{
    return [self isZincResourceOfType:@"archive"];
}

- (NSString*) zincBundleId
{
    if (![self isZincManifestResource] &&
        ![self isZincBundleResource] &&
        ![self isZincArchiveResource]) {
        return nil;
    }
    
    NSString* bundleId = [self path];
    bundleId = [bundleId stringByDeletingLastPathComponent]; // strip version
    bundleId = [bundleId substringFromIndex:1]; // strip leading /
    return bundleId;
}

- (ZincVersion) zincBundleVersion
{
    if (![self isZincManifestResource] &&
        ![self isZincBundleResource] &&
        ![self isZincArchiveResource]) {
        return ZincVersionInvalid;
    }
    
    NSString* version = [self path];
    version = [version lastPathComponent];
    return [version integerValue];
}

+ (NSURL*) zincResourceForObjectWithSHA:(NSString*)sha inCatalogId:(NSString*)catalogId
{
    NSString* path = [NSString stringWithFormat:@"/%@/%@", catalogId, sha];
    return [[[NSURL alloc] initWithScheme:ZINC_RESOURCE_SCHEME host:@"object" path:path] autorelease];
}

- (BOOL) isZincObjectResource
{
    return [self isZincResourceOfType:@"object"];
}

- (NSString*) zincObjectSHA
{
    if (![self isZincObjectResource]) {
        return nil;
    }
    
    return [[self path] lastPathComponent];
}

@end
