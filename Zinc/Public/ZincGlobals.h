//
//  Zinc.h
//  Zinc
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#ifndef _ZINC_GLOBALS_
#define _ZINC_GLOBALS_

extern NSString* const kZincPackageName;

typedef NSInteger ZincFormat;
typedef NSInteger ZincVersion;


enum  {
    ZincFormatInvalid = -1,
};


enum  {
    ZincVersionInvalid = -1,
    ZincVersionUnknown = 0,
};


typedef enum {
    ZincBundleStateNone      = 0,
    ZincBundleStateCloning   = 1,
    ZincBundleStateAvailable = 2,
    ZincBundleStateDeleting  = 3,
    ZincBundleStateInvalid   = -1,
} ZincBundleState;


typedef NS_ENUM(NSInteger, ZincBundleVersionSpecifier) {
    /**
     Any version, including bootstrapped "unversioned" bundles will be accepted.
     */
    ZincBundleVersionSpecifierAny,

    /**
     Allow any version but an `ZincVersionUnknown`, which occurs with generated
     bootstrapped manifests.
     */
    ZincBundleVersionSpecifierNotUnknown,

    /**
     Require that the version is up to date with the tracked distro version
     in the catalog.
     */
    ZincBundleVersionSpecifierCatalogOnly,

    /**
     Require that the version is up to date with the tracked distro version
     in the catalog OR the version is `ZincVersionUnknown`.
     */
    ZincBundleVersionSpecifierCatalogOrUnknown,

    ZincBundleVersionSpecifierDefault = ZincBundleVersionSpecifierCatalogOrUnknown,
};


extern NSString* const ZincBundleStateName[];

extern NSString* const ZincFileFormatRaw;
extern NSString* const ZincFileFormatGZ;

typedef void (^ZincCompletionBlock)(NSArray* errors);

#endif