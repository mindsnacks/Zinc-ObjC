//
//  ZCRepo.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/16/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

// TODO: add zinc prefix to everything?

@class ZincCatalog;

@interface NSURL (ZincSource)

- (NSURL*) urlForCatalogIndex;
- (NSURLRequest*) urlRequestForCatalogIndex;

- (NSURL*) urlForBundleName:(NSString*)name version:(NSInteger)version;
- (NSURLRequest*) urlRequestForBundleName:(NSString*)name version:(NSInteger)version;

- (NSURL*) urlForBundleName:(NSString*)name distribution:(NSString*)distro catalog:(ZincCatalog*)catalog;
- (NSURLRequest*) urlRequestForBundleName:(NSString*)name distribution:(NSString*)distro catalog:(ZincCatalog*)index;

- (NSURL*) urlForFileWithSHA:(NSString*)sha extension:(NSString*)extension;
- (NSURL*) urlForFileWithSHA:(NSString*)sha;
- (NSURLRequest*) urlRequestForFileWithSHA:(NSString*)sha extension:(NSString*)extension;
- (NSURLRequest*) urlRequestForFileWithSHA:(NSString*)sha;

@end
