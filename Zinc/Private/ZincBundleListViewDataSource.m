//
//  ZincBundleListViewDataSource.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/7/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincBundleListViewDataSource.h"

#import "ZincRepo.h"
#import "ZincInternals.h"


@interface ZincBundleListViewDataSource ()

@property (nonatomic, retain, readwrite) ZincRepo *repo;
@property (nonatomic, retain, readwrite) NSArray *sortedCatalogIDs;
@property (nonatomic, retain, readwrite) NSDictionary *sortedBundleIDsByCatalogID;

@end


@implementation ZincBundleListViewDataSource

- (id) initWithRepo:(ZincRepo *)repo
{
    NSParameterAssert(repo);

    self = [super init];
    if (self) {
        self.repo = repo;
    }
    return self;
}

- (void)reload
{
    //    self.sortedBundleIDs = [[[self.repo trackedBundleIDs] allObjects] sortedArrayUsingSelector:@selector(compare:)];

    NSMutableSet *catalogIDs = [[NSMutableSet alloc] init];
    NSMutableDictionary *sortedBundleIDsByCatalogID = [[NSMutableDictionary alloc] init];

    for (NSString *bundleID in [self.repo trackedBundleIDs]) {

        NSString *catalogID = ZincCatalogIDFromBundleID(bundleID);
        NSString *bundleName = ZincBundleNameFromBundleID(bundleID);

        // add catalog id
        [catalogIDs addObject:catalogID];

        // add bundle names
        NSMutableArray *bundleNames = sortedBundleIDsByCatalogID[catalogID];
        if (bundleNames == nil) {
            bundleNames = [[NSMutableArray alloc] init];
            sortedBundleIDsByCatalogID[catalogID] = bundleNames;
        }
        [bundleNames addObject:bundleName];
    }

    // store
    self.sortedCatalogIDs = [[catalogIDs allObjects] sortedArrayUsingSelector:@selector(compare:)];

    [sortedBundleIDsByCatalogID enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        sortedBundleIDsByCatalogID[key] = [obj sortedArrayUsingSelector:@selector(compare:)];
    }];
    self.sortedBundleIDsByCatalogID = sortedBundleIDsByCatalogID;
}

- (NSUInteger)numberOfBundlesInCatalogAtIndex:(NSUInteger)index
{
    NSString *catalogID = self.sortedCatalogIDs[index];
    return [self.sortedBundleIDsByCatalogID[catalogID] count];
}

- (NSString *)bundleIDAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *catalogID = self.sortedCatalogIDs[[indexPath indexAtPosition:0]];
    NSString *bundleName = self.sortedBundleIDsByCatalogID[catalogID][[indexPath indexAtPosition:1]];
    return ZincBundleIDFromCatalogIDAndBundleName(catalogID, bundleName);

}

//- (NSString *)bundleNameAtIndexPath:(NSIndexPath *)indexPath
//{
//    return ZincBundleNameFromBundleID([self bundleIDAtIndexPath:indexPath]);
//}


@end
