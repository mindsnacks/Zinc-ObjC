//
//  ZCRepo.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/16/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

// TODO: rename to NSURL (ZincCatalog)?
// TODO: add zinc prefix to everything?

@class ZincCatalog;

@interface NSURL (ZincSource)

- (NSURL*) urlForCatalogIndex;
- (NSURLRequest*) urlRequestForCatalogIndex;

- (NSURL*) urlForBundleName:(NSString*)name version:(NSInteger)version;
- (NSURLRequest*) zincManifestURLRequestForBundleName:(NSString*)name version:(NSInteger)version;

- (NSURL*) urlForBundleName:(NSString*)name distribution:(NSString*)distro catalog:(ZincCatalog*)catalog;
- (NSURLRequest*) urlRequestForBundleName:(NSString*)name distribution:(NSString*)distro catalog:(ZincCatalog*)index;

- (NSURL*) urlForFileWithSHA:(NSString*)sha extension:(NSString*)extension;
- (NSURL*) urlForFileWithSHA:(NSString*)sha;
- (NSURLRequest*) urlRequestForFileWithSHA:(NSString*)sha extension:(NSString*)extension;
- (NSURLRequest*) urlRequestForFileWithSHA:(NSString*)sha;

- (NSURL*) urlForArchivedBundleName:(NSString*)name version:(NSInteger)version flavor:(NSString*)flavor;
- (NSURLRequest*) urlRequestForArchivedBundleName:(NSString*)name version:(NSInteger)version;
- (NSURLRequest*) urlRequestForArchivedBundleName:(NSString*)name version:(NSInteger)version flavor:(NSString*)flavor;

@end
