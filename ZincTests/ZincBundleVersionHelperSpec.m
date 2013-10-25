//
//  ZincBundleVersionHelperSpec.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 10/24/13.
//  Copyright 2013 MindSnacks. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "ZincBundleVersionHelper.h"
#import "ZincRepo+Private.h"
#import "ZincRepoIndex.h"
#import "ZincGlobals.h"

SPEC_BEGIN(ZincBundleVersionHelperSpec)

describe(@"ZincBundleVersionHelper", ^{

    __block ZincBundleVersionHelper* versionHelper;
    __block id repoIndex = [ZincRepoIndex mock];
    __block id repo = [ZincRepo mock];
    NSString* bundleID = @"com.mindsnacks.noodle";
    NSString* distro = @"master";

    beforeEach(^{

        repoIndex = [ZincRepoIndex mock];

        repo = [ZincRepo mock];
        [repo stub:@selector(index) andReturn:repoIndex];

        versionHelper = [[ZincBundleVersionHelper alloc] init];
    });

    context(@"versionForBundleID", ^{

        context(@"repo has no version", ^{

            beforeEach(^{
                [[repoIndex stubAndReturn:@[]] availableVersionsForBundleID:bundleID];
                [[repo stubAndReturn:theValue(ZincVersionInvalid)] catalogVersionForBundleID:bundleID distribution:distro];
            });

            it(@"ZincBundleVersionSpecifierAny", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierAny /**/ repo:repo])
                  should] equal:theValue(/**/ ZincVersionInvalid /**/ )];
            });

            it(@"ZincBundleVersionSpecifierNotUnknown", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierNotUnknown /**/ repo:repo])
                  should] equal:theValue(/**/ ZincVersionInvalid /**/ )];
            });

            it(@"ZincBundleVersionSpecifierCatalogOnly", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierCatalogOnly /**/ repo:repo])
                  should] equal:theValue(/**/ ZincVersionInvalid /**/ )];
            });

            it(@"ZincBundleVersionSpecifierCatalogOrUnknown", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierCatalogOrUnknown /**/ repo:repo])
                  should] equal:theValue(/**/ ZincVersionInvalid /**/ )];
            });
        });

        context(@"repo has unknown version only", ^{

            beforeEach(^{
                [[repoIndex stubAndReturn:@[@(ZincVersionUnknown)]] availableVersionsForBundleID:bundleID];
                [[repo stubAndReturn:theValue(ZincVersionInvalid)] catalogVersionForBundleID:bundleID distribution:distro];
            });

            it(@"ZincBundleVersionSpecifierAny", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierAny /**/ repo:repo])
                  should] equal:theValue(/**/ ZincVersionUnknown /**/ )];
            });

            it(@"ZincBundleVersionSpecifierNotUnknown", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierNotUnknown /**/ repo:repo])
                  should] equal:theValue(/**/ ZincVersionInvalid /**/ )];
            });

            it(@"ZincBundleVersionSpecifierCatalogOnly", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierCatalogOnly /**/ repo:repo])
                  should] equal:theValue(/**/ ZincVersionInvalid /**/ )];
            });

            it(@"ZincBundleVersionSpecifierCatalogOrUnknown", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierCatalogOrUnknown /**/ repo:repo])
                  should] equal:theValue(/**/ ZincVersionUnknown /**/ )];
            });
        });

        context(@"repo has non-catalog version only", ^{

            ZincVersion catalogVersion = 6;
            ZincVersion otherVersion = 7;

            beforeEach(^{
                [[repoIndex stubAndReturn:@[@(otherVersion)]] availableVersionsForBundleID:bundleID];
                [[repo stubAndReturn:theValue(catalogVersion)] catalogVersionForBundleID:bundleID distribution:distro];
            });

            it(@"ZincBundleVersionSpecifierAny", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierAny /**/ repo:repo])
                  should] equal:theValue(/**/ otherVersion /**/ )];
            });

            it(@"ZincBundleVersionSpecifierNotUnknown", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierNotUnknown /**/ repo:repo])
                  should] equal:theValue(/**/ otherVersion /**/ )];
            });

            it(@"ZincBundleVersionSpecifierCatalogOnly", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierCatalogOnly /**/ repo:repo])
                  should] equal:theValue(/**/ ZincVersionInvalid /**/ )];
            });

            it(@"ZincBundleVersionSpecifierCatalogOrUnknown", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierCatalogOrUnknown /**/ repo:repo])
                  should] equal:theValue(/**/ ZincVersionInvalid /**/ )];
            });
        });

        context(@"repo has non-catalog and unknown version", ^{

            const ZincVersion catalogVersion = 6;
            const ZincVersion otherVersion = 7;

            beforeEach(^{
                [[repoIndex stubAndReturn:@[@(ZincVersionUnknown), @(otherVersion)]] availableVersionsForBundleID:bundleID];
                [[repo stubAndReturn:theValue(catalogVersion)] catalogVersionForBundleID:bundleID distribution:distro];
            });

            it(@"ZincBundleVersionSpecifierAny", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierAny /**/ repo:repo])
                  should] equal:theValue(/**/ otherVersion /**/ )];
            });

            it(@"ZincBundleVersionSpecifierNotUnknown", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierNotUnknown /**/ repo:repo])
                  should] equal:theValue(/**/ otherVersion /**/ )];
            });

            it(@"ZincBundleVersionSpecifierCatalogOnly", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierCatalogOnly /**/ repo:repo])
                  should] equal:theValue(/**/ ZincVersionInvalid /**/ )];
            });

            it(@"ZincBundleVersionSpecifierCatalogOrUnknown", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierCatalogOrUnknown /**/ repo:repo])
                  should] equal:theValue(/**/ ZincVersionUnknown /**/ )];
            });
        });

        context(@"repo has catalog and other versions", ^{

            const ZincVersion catalogVersion = 6;
            const ZincVersion otherVersion = 7;

            beforeEach(^{
                [[repoIndex stubAndReturn:@[@(ZincVersionUnknown), @(otherVersion), @(catalogVersion)]] availableVersionsForBundleID:bundleID];
                [[repo stubAndReturn:theValue(catalogVersion)] catalogVersionForBundleID:bundleID distribution:distro];
            });

            it(@"ZincBundleVersionSpecifierAny", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierAny /**/ repo:repo])
                  should] equal:theValue(/**/ catalogVersion /**/ )];
            });

            it(@"ZincBundleVersionSpecifierNotUnknown", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierNotUnknown /**/ repo:repo])
                  should] equal:theValue(/**/ catalogVersion /**/ )];
            });

            it(@"ZincBundleVersionSpecifierCatalogOnly", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierCatalogOnly /**/ repo:repo])
                  should] equal:theValue(/**/ catalogVersion /**/ )];
            });

            it(@"ZincBundleVersionSpecifierCatalogOrUnknown", ^{
                [[theValue([versionHelper versionForBundleID:bundleID distribution:distro
                                            versionSpecifier:/**/ ZincBundleVersionSpecifierCatalogOrUnknown /**/ repo:repo])
                  should] equal:theValue(/**/ catalogVersion /**/ )];
            });
        });
    });
});

SPEC_END
