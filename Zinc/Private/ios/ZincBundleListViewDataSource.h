//
//  ZincBundleListViewDataSource.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/7/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZincRepo;

@interface ZincBundleListViewDataSource : NSObject

- (id) initWithRepo:(ZincRepo *)repo;

@property (nonatomic, retain, readonly) NSArray *sortedCatalogIDs;
@property (nonatomic, retain, readonly) NSDictionary *sortedBundleIDsByCatalogID;

- (NSUInteger)numberOfBundlesInCatalogAtIndex:(NSUInteger)index;

- (NSString *)bundleIDAtIndexPath:(NSIndexPath *)indexPath;
//- (NSString *)bundleNameAtIndexPath:(NSIndexPath *)indexPath;

- (void)reload;

@end
