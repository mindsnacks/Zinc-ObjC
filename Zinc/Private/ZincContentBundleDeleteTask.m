//
//  ZincContentBundleDeleteTask.m
//  Zinc-ObjC
//
//  Created by Matthew Sun on 3/28/17.
//  Copyright © 2017 MindSnacks. All rights reserved.
//

#import "ZincContentBundleDeleteTask.h"

@implementation ZincContentBundleDeleteTask

+ (NSString *)action
{
    return @"ContentBundleDelete";
}

- (void) doMaintenance
{
    NSLog(@"ContentBundleDelete started");

    /*
    if ([self ms_totalSizeOfContentBundles] < kContentBundleFlushLimitInMegabytes) {
        return;
    }

    NSMutableSet<NSURL *> *contentBundleURLs = [NSMutableSet new];
    NSMutableSet<NSString *> *contentBundleIDs = [NSMutableSet new];
    [self ms_forBundlesWithPrefix:kContentBundlePrefix performBlock:^(NSURL *bundleURL) {
        NSString *bundleName = [self ms_bundleNameForBundleURL:bundleURL];
        NSString *bundleID = [self ms_contentBundleIDForContentBundleName:bundleName];

        [contentBundleURLs addObject:bundleURL];
        [contentBundleIDs addObject:bundleID];
    }];

    if (![self ms_deleteFromRepoJSONBundleEntriesWithBundleIDs:contentBundleIDs]) {
        NSLog(@"Unable to update repo.json, will not delete bundles/manifests");
        return;
    }

    for (NSURL *bundleURL in contentBundleURLs) {
        NSString *bundleName = [self ms_bundleNameForBundleURL:bundleURL];
        NSString *manifestName = [self ms_manifestNameForBundleName:bundleName];
        NSURL *manifestURL = [self ms_manifestURLForManifestName:manifestName];

        if ([self ms_deleteFileAtURL:manifestURL]) {
            [self ms_deleteFileAtURL:bundleURL];
        } else {
            NSLog(@"Failed to delete a manifest, will not delete the related bundle: %@",
                  bundleURL);
        }
    }

    MSAnalyticsIntegration *analyticsIntegration = MSInjectionCreateObject(MSAnalyticsIntegration);
    [analyticsIntegration trackActionWithName:@"StoredContentCleared"
                               withProperties:@{}];
     */

    NSLog(@"ContentBundleDelete done");
}

@end
