//
//  ZincResource.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"


/**
 NSUSL extensions for working with Zinc resources.
 
 These extenstions are part of the *Zinc Public API*.
 */
@interface NSURL (ZincResource)

///------------------------
/// @name Catalog resources
///------------------------

/**
 Create a Zinc resource URL for a catalog
 
 @param catalogID The catalog ID

 @return A Zinc resource URL for the catalog
 */
+ (NSURL*) zincResourceForCatalogWithId:(NSString*)catalogID;

/**
 Determines if URL is a Zinc catalog resource URL

 @return YES if catalog resource URL, NO otherwise
 */
- (BOOL) isZincCatalogResource;

///-------------------------
/// @name Manifest resources
///-------------------------

/**
 Create a Zinc resource URL for a manifest

 @param bundleID The bundleID
 @param version The version

 @return A Zinc resource URL for the manifest
 */
+ (NSURL*) zincResourceForManifestWithId:(NSString*)bundleID version:(ZincVersion)version;

/**
 Determines if URL is a Zinc manifest resource URL

 @return YES if manifest resource URL, NO otherwise
 */
- (BOOL) isZincManifestResource;

///-----------------------
/// @name Bundle resources
///-----------------------

/**
 Create a Zinc resource URL for a bundle, using a bundle ID and version

 @param bundleID The bundle ID
 @param version The bundle version

 @return A Zinc resource URL for the bundle
 */
+ (NSURL*) zincResourceForBundleWithID:(NSString*)bundleID version:(ZincVersion)version;

/**
 Create a Zinc resource URL for a bundle, using a bundle bundleDescriptor

 @param bundleDescriptor The bundle descriptor

 @return A Zinc resource URL for the bundle
 */
+ (NSURL*) zincResourceForBundleDescriptor:(NSString*)bundleDescriptor;

/**
 Determines if URL is a Zinc bundle resource URL

 @return YES if bundle resource URL, NO otherwise
 */
- (BOOL) isZincBundleResource;

///------------------------
/// @name Archive resources
///------------------------

/**
 Create a Zinc resource URL for a archive, using a bundle ID and version

 @param bundleID The bundle ID
 @param version The bundle version

 @return A Zinc resource URL for the archive
 */
+ (NSURL*) zincResourceForArchiveWithId:(NSString*)bundleID version:(ZincVersion)version;

/**
 Determines if URL is a Zinc archive resource URL

 @return YES if archive resource URL, NO otherwise
 */
- (BOOL) isZincArchiveResource;

///----------------------------
/// @name File/Object resources
///----------------------------

/**
 Create a Zinc resource URL for a file-object

 @param sha The file's sha
 @param catalogID The catalog ID

 @return A Zinc resource URL for the file-object
 */
+ (NSURL*) zincResourceForObjectWithSHA:(NSString*)sha inCatalogID:(NSString*)catalogID;

/**
 Determines if URL is a Zinc file object resource URL

 @return YES if file object resource URL, NO otherwise
 */
- (BOOL) isZincObjectResource;

/**
 Get the SHA from a file-object.

 @return The SHA if resource is a file-object resource, nil otherwise.
 */
- (NSString*) zincObjectSHA;

///----------------------
/// @name General methods
///----------------------

/**
 Gets the Zinc catalog ID as a string from a Zinc resource URL.

 @return The catalog ID if resource is a catalog, manifest, bundle, archive, or file-object. nil otherwise.
 */
- (NSString*) zincCatalogID;

/**
 Gets the Zinc bundle ID as a string from a Zinc resource URL.

 @return The bundle ID if resource is a manifest, bundle or archive. nil otherwise.
 */
- (NSString*) zincBundleID;

/**
 Gets the Zinc bundle ID from a Zinc resource URL.

 @return The version if resource is a manifest, bundle or archive. nil otherwise.
 */
- (ZincVersion) zincBundleVersion;

@end
