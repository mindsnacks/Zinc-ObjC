//
//  ZincResourceDescriptor.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincResource.h"

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
    if (![self isZincCatalogResource]) {
        return nil;
    }
    return [[self path] substringFromIndex:1];
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

- (NSString*) zincBundleId
{
    if (![self isZincManifestResource] && ![self isZincBundleResource]) {
        return nil;
    }
    
    NSString* bundleId = [self path];
    bundleId = [bundleId stringByDeletingLastPathComponent]; // strip version
    bundleId = [bundleId substringFromIndex:1]; // strip leading /
    return bundleId;
}

- (ZincVersion) zincBundleVersion
{
    if (![self isZincManifestResource] && ![self isZincBundleResource]) {
        return ZincVersionInvalid;
    }
    
    NSString* version = [self path];
    version = [version lastPathComponent];
    return [version integerValue];
}

+ (NSURL*) zincResourceForFileWithSHA:(NSString*)sha
{
    NSString* path = [@"/" stringByAppendingString:sha];
    return [[[NSURL alloc] initWithScheme:ZINC_RESOURCE_SCHEME host:@"object" path:path] autorelease];
}

- (BOOL) isZincFileResource
{
    return [self isZincResourceOfType:@"object"];
}

- (NSString*) zincFileSHA
{
    if (![self isZincFileResource]) {
        return nil;
    }
    
    return [[self path] substringFromIndex:1];
}

@end
