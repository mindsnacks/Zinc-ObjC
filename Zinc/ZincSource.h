//
//  ZCRepo.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/16/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZincCatalog;

@interface ZincSource : NSObject

+ (ZincSource*) sourceWithURL:(NSURL*)url;
@property (nonatomic, retain, readonly) NSURL* url;

- (NSURL*) urlForCatalogIndex;
- (NSURLRequest*) urlRequestForCatalogIndex;

- (NSURL*) urlForBundleName:(NSString*)name version:(NSInteger)version;
- (NSURLRequest*) urlRequestForBundleName:(NSString*)name version:(NSInteger)version;

- (NSURL*) urlForBundleName:(NSString*)name label:(NSString*)label catalog:(ZincCatalog*)catalog;
- (NSURLRequest*) urlRequestForBundleName:(NSString*)name label:(NSString*)label catalog:(ZincCatalog*)index;

@end
