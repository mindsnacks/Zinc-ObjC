//
//  ZincRepoExternalBundleRef.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/15/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincExternalBundleInfo.h"

@implementation ZincExternalBundleInfo

+ (ZincExternalBundleInfo*) infoForBundleResource:(NSURL*)resource manifestPath:(NSString*)manifestPath bundleRootPath:(NSString*)bundleRootPath
{
    NSParameterAssert(resource);
    NSParameterAssert(manifestPath);
    NSParameterAssert(bundleRootPath);
    ZincExternalBundleInfo* ref = [[ZincExternalBundleInfo alloc] init];
    ref.bundleResource = resource;
    ref.manifestPath = manifestPath;
    ref.bundleRootPath = bundleRootPath;
    return ref;
}


- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@: %p bundleResource=%@ manifestPath='%@' bundleRootPath='%@'>",
            [self class], self, self.bundleResource, self.manifestPath, self.bundleRootPath];
}

@end
