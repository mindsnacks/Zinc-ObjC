//
//  ZincBundleVersionHelper.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 10/24/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincBundleVersionHelper.h"
#import "ZincRepo+Private.h"
#import "ZincResource.h"

@implementation ZincBundleVersionHelper

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (ZincVersion) versionForBundleID:(NSString*)bundleID distribution:(NSString*)distro versionSpecifier:(ZincBundleVersionSpecifier)versionSpec repo:(ZincRepo*)repo
{
    NSArray* availableVersions = [repo.index availableVersionsForBundleID:bundleID];
    ZincVersion latestAvailableVersion = ZincVersionInvalid;
    if ([availableVersions count] > 0) {
        latestAvailableVersion = [[availableVersions lastObject] integerValue];
    }

    ZincVersion catalogVersion = ZincVersionInvalid;
    if (distro != nil) {
        catalogVersion = [repo catalogVersionForBundleID:bundleID distribution:distro];
    }

    ZincVersion resolvedVersion = ZincVersionInvalid;

    if ([availableVersions containsObject:@(catalogVersion)]) {

        // Always defer to the catalog version if available
        resolvedVersion = catalogVersion;

    } else {

        switch (versionSpec) {

            case ZincBundleVersionSpecifierCatalogOnly:
                break;

            case ZincBundleVersionSpecifierCatalogOrUnknown:
                if ([availableVersions containsObject:@(ZincVersionUnknown)]) {
                    resolvedVersion = ZincVersionUnknown;
                }
                break;

            case ZincBundleVersionSpecifierNotUnknown:
                if (latestAvailableVersion != ZincVersionUnknown) {
                    resolvedVersion = latestAvailableVersion;
                }
                break;

            case ZincBundleVersionSpecifierAny:
                resolvedVersion = latestAvailableVersion;
                break;
                
            default:
                NSAssert(NO, @"unhandled case: %ld", (long)versionSpec);
                break;
        }
    }
    
    return resolvedVersion;
}


- (ZincVersion) versionForBundleID:(NSString *)bundleID versionSpecifier:(ZincBundleVersionSpecifier)versionSpec repo:(ZincRepo*)repo
{
    return [self versionForBundleID:bundleID distribution:[repo.index trackedDistributionForBundleID:bundleID] versionSpecifier:versionSpec repo:repo];
}

- (ZincVersion) versionForBundleID:(NSString *)bundleID repo:(ZincRepo*)repo
{
    return [self versionForBundleID:bundleID versionSpecifier:ZincBundleVersionSpecifierDefault repo:repo];
}

- (ZincVersion) currentDistroVersionForBundleID:(NSString*)bundleID repo:(ZincRepo*)repo
{
    NSString* distro = [repo.index trackedDistributionForBundleID:bundleID];
    return [repo catalogVersionForBundleID:bundleID distribution:distro];
}

- (BOOL) bundleResource:(NSURL*)bundleResource satisfiesVersionSpecifier:(ZincBundleVersionSpecifier)versionSpec repo:(ZincRepo*)repo
{
    BOOL hasVersion = NO;
    NSString* bundleID = [bundleResource zincBundleID];
    ZincVersion version = [bundleResource zincBundleVersion];

    switch (versionSpec) {
        case ZincBundleVersionSpecifierAny:
            hasVersion = (version != ZincVersionInvalid);
            break;

        case ZincBundleVersionSpecifierNotUnknown:
            hasVersion = (version > 0);
            break;

        case ZincBundleVersionSpecifierCatalogOnly:
            hasVersion = (version == [self currentDistroVersionForBundleID:bundleID repo:repo]);
            break;

        case ZincBundleVersionSpecifierCatalogOrUnknown:
            hasVersion = (version == ZincVersionInvalid || [self currentDistroVersionForBundleID:bundleID repo:repo]);
            break;

        default:
            NSAssert(NO, @"unhandled case: %ld", (long)versionSpec);
            break;
    }
    return hasVersion;
}

- (BOOL) hasSpecifiedVersion:(ZincBundleVersionSpecifier)versionSpec forBundleID:(NSString*)bundleID repo:(ZincRepo*)repo
{
    return ([self versionForBundleID:bundleID versionSpecifier:versionSpec repo:repo] != ZincVersionInvalid);
}

@end
