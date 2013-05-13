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

+ (NSURL*) zincResourceForCatalogWithId:(NSString*)catalogID
{
    NSString* path = [@"/" stringByAppendingString:catalogID];
   return [[[NSURL alloc] initWithScheme:ZINC_RESOURCE_SCHEME host:@"catalog" path:path] autorelease];
}

- (BOOL) isZincCatalogResource
{
    return [self isZincResourceOfType:@"catalog"];
}

- (NSString*) zincCatalogID
{
    if ([self isZincCatalogResource]) {
        return [[self path] substringFromIndex:1];
        
    } else if ([self isZincBundleResource]) {
        return ZincCatalogIDFromBundleID([self zincBundleID]);

    } else if ([self isZincObjectResource]) {
        NSString* catalogID = [self path];
        catalogID = [catalogID stringByDeletingLastPathComponent]; // strip version
        catalogID = [catalogID substringFromIndex:1]; // strip leading /
        return catalogID;
    }
    
    return nil;
}

+ (NSURL*) zincResourceForManifestWithId:(NSString*)bundleID version:(ZincVersion)version
{
    NSString* path = [NSString stringWithFormat:@"/%@/%d", bundleID, version];
    return [[[NSURL alloc] initWithScheme:ZINC_RESOURCE_SCHEME host:@"manifest" path:path] autorelease];
}

- (BOOL) isZincManifestResource
{
    return [self isZincResourceOfType:@"manifest"];
}

+ (NSURL*) zincResourceForBundleWithID:(NSString*)bundleID version:(ZincVersion)version
{
    NSString* path = [NSString stringWithFormat:@"/%@/%d", bundleID, version];
    return [[[NSURL alloc] initWithScheme:ZINC_RESOURCE_SCHEME host:@"bundle" path:path] autorelease];
}

+ (NSURL*) zincResourceForBundleDescriptor:(NSString*)bundleDescriptor
{
    NSString* bundleID = ZincBundleIDFromBundleDescriptor(bundleDescriptor);
    ZincVersion version = ZincBundleVersionFromBundleDescriptor(bundleDescriptor);
    return [self zincResourceForBundleWithID:bundleID version:version];
}

- (BOOL) isZincBundleResource
{
    return [self isZincResourceOfType:@"bundle"];
}

+ (NSURL*) zincResourceForArchiveWithId:(NSString*)bundleID version:(ZincVersion)version
{
    NSString* path = [NSString stringWithFormat:@"/%@/%d", bundleID, version];
    return [[[NSURL alloc] initWithScheme:ZINC_RESOURCE_SCHEME host:@"archive" path:path] autorelease];
}

- (BOOL) isZincArchiveResource
{
    return [self isZincResourceOfType:@"archive"];
}

- (NSString*) zincBundleID
{
    if (![self isZincManifestResource] &&
        ![self isZincBundleResource] &&
        ![self isZincArchiveResource]) {
        return nil;
    }
    
    NSString* bundleID = [self path];
    bundleID = [bundleID stringByDeletingLastPathComponent]; // strip version
    bundleID = [bundleID substringFromIndex:1]; // strip leading /
    return bundleID;
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

+ (NSURL*) zincResourceForObjectWithSHA:(NSString*)sha inCatalogID:(NSString*)catalogID
{
    NSString* path = [NSString stringWithFormat:@"/%@/%@", catalogID, sha];
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
