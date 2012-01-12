//
//  ZincResourceDescriptor.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincResourceDescriptor.h"

@implementation ZincCatalogDescriptor

@synthesize catalogId = _catalogId;

+ (id) catalogDescriptorForId:(NSString*)catalogId
{
    ZincCatalogDescriptor* desc = [[[ZincCatalogDescriptor alloc] init] autorelease];
    desc.catalogId = catalogId;
    return desc;
}

- (void)dealloc 
{
    self.catalogId = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    ZincCatalogDescriptor* newdesc = [[ZincCatalogDescriptor allocWithZone:zone] init];
    newdesc.catalogId = [[self.catalogId copy] autorelease];
    return newdesc;
}

@end


@implementation ZincManifestDescriptor

@synthesize bundleId = _bundleId;
@synthesize version = _version;

+ (id) manifestDescriptorForId:(NSString*)bundleId version:(ZincVersion)version
{
    ZincManifestDescriptor* desc = [[[ZincManifestDescriptor alloc] init] autorelease];
    desc.bundleId = bundleId;
    desc.version = version;
    return desc;
}

- (void)dealloc 
{
    self.bundleId = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    ZincManifestDescriptor* newdesc = [[ZincManifestDescriptor allocWithZone:zone] init];
    newdesc.bundleId = [[self.bundleId copy] autorelease];
    newdesc.version = self.version;
    return newdesc;
}

@end


@implementation ZincFileDescriptor

@synthesize sha = _sha;

+ (id) fileDescriptorForSHA:(NSString*)sha
{
    ZincFileDescriptor* desc = [[[ZincFileDescriptor alloc] init] autorelease];
    desc.sha = sha;
    return desc;
}

- (void)dealloc 
{
    self.sha = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    ZincFileDescriptor* newdesc = [[ZincFileDescriptor allocWithZone:zone] init];
    newdesc.sha = [[self.sha copy] autorelease];
    return newdesc;
}

@end