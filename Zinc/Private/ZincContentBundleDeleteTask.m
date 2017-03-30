//
//  ZincContentBundleDeleteTask.m
//  Zinc-ObjC
//
//  Created by Matthew Sun on 3/28/17.
//  Copyright © 2017 MindSnacks. All rights reserved.
//

#import "ZincContentBundleDeleteTask.h"

#import <UIKit/UIKit.h>

#if DEBUG
static const CGFloat kContentBundleFlushLimitInMegabytes = 20.f;
#else
static const CGFloat kContentBundleFlushLimitInMegabytes = 100.f;
#endif

#if DEBUG
static NSString * const kGameBundlePrefix = @"com.wonder.moai_games";
#endif

static NSString * const kContentBundlePrefix = @"com.wonder.content";

@implementation ZincContentBundleDeleteTask

#pragma mark - 

+ (NSString *)action {
    return @"ContentBundleDelete";
}

- (void)doMaintenance {
    NSLog(@"ContentBundleDelete started");

    /*
    if ([self totalSizeOfContentBundles] < kContentBundleFlushLimitInMegabytes) {
        return;
    }
     */

    NSMutableSet<NSURL *> *contentBundleURLs = [NSMutableSet new];
    NSMutableSet<NSString *> *contentBundleIDs = [NSMutableSet new];
    [self forBundlesWithPrefix:kContentBundlePrefix performBlock:^(NSURL *bundleURL) {
        NSString *bundleName = [self bundleNameForBundleURL:bundleURL];
        NSString *bundleID = [self contentBundleIDForContentBundleName:bundleName];

        [contentBundleURLs addObject:bundleURL];
        [contentBundleIDs addObject:bundleID];
    }];

    if (![self deleteFromRepoJSONBundleEntriesWithBundleIDs:contentBundleIDs]) {
        NSLog(@"Unable to update repo.json, will not delete bundles/manifests");
        return;
    }

    for (NSURL *bundleURL in contentBundleURLs) {
        NSString *bundleName = [self bundleNameForBundleURL:bundleURL];
        NSString *manifestName = [self manifestNameForBundleName:bundleName];
        NSURL *manifestURL = [self manifestURLForManifestName:manifestName];

        if ([self deleteFileAtURL:manifestURL]) {
            [self deleteFileAtURL:bundleURL];
        } else {
            NSLog(@"Failed to delete a manifest, will not delete the related bundle: %@",
                  bundleURL);
        }
    }

    /*
    MSAnalyticsIntegration *analyticsIntegration = MSInjectionCreateObject(MSAnalyticsIntegration);
    [analyticsIntegration trackActionWithName:@"StoredContentCleared"
                               withProperties:@{}];
     */

    NSLog(@"ContentBundleDelete done");
}

#pragma mark - repo.json

- (NSURL *)repoJSONURL {
    return [self absoluteURLForPathRelativeToZincFolder:@"repo.json" isDirectory:NO];
}

- (NSString *)repoJSONPath {
    return [[self repoJSONURL] path];
}

/* returns `nil` if error during reading
 */
- (NSDictionary *)repoJSONDict {
    NSString *repoJSONPath = [self repoJSONPath];

    NSError *error;

    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:repoJSONPath];
    [inputStream open];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithStream:inputStream
                                                               options:0
                                                                 error:&error];
    [inputStream close];

    if (error) {
        NSLog(@"Error while converting json file to NSDictionary: %@", repoJSONPath);
        return nil;
    }

    return jsonDict;
}

/* return YES if success, NO otherwise
 */
- (BOOL)writeToRepoJSONWithJSONDict:(NSDictionary *)jsonDict {
    [self deleteFileAtURL:self.repoJSONURL];

    NSString *repoJSONPath = [self repoJSONPath];
    NSError *error;

    NSOutputStream *outputStream = [[NSOutputStream alloc] initToFileAtPath:repoJSONPath
                                                                     append:NO];
    [outputStream open];
    [NSJSONSerialization writeJSONObject:jsonDict
                                toStream:outputStream
                                 options:0
                                   error:&error];
    [outputStream close];

    if (error) {
        NSLog(@"couldn't write to file: %@", repoJSONPath);
    }

    return !error;
}

- (BOOL)deleteFromRepoJSONBundleEntriesWithBundleIDs:(NSSet<NSString *> *)bundleIDs {
    NSMutableDictionary *repoJSONDict = [[self repoJSONDict] mutableCopy];
    if (repoJSONDict == nil) {
        return NO;
    }

    NSString * const bundlesKey = @"bundles";
    NSDictionary<NSString *, id> *originalBundlesByID = repoJSONDict[bundlesKey];
    NSMutableDictionary<NSString *, id> *newBundlesByID = [NSMutableDictionary new];

    [originalBundlesByID enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull bundleID,
                                                             id _Nonnull value,
                                                             BOOL * _Nonnull stop) {
        if (![bundleIDs containsObject:bundleID]) {
            newBundlesByID[bundleID] = value;
        }
    }];

    repoJSONDict[bundlesKey] = [newBundlesByID copy];

    return [self writeToRepoJSONWithJSONDict:repoJSONDict];
}

#pragma mark - File Path

- (NSURL *)urlForSearchPathDirectory:(NSSearchPathDirectory)searchPathDirectory {
    NSURL *url = [NSFileManager.defaultManager URLsForDirectory:searchPathDirectory inDomains:NSUserDomainMask][0];
    NSAssert(url != nil, @"url not found for NSSearchPathDirectory: %ld", (long)searchPathDirectory);
    return url;
}

- (NSURL *)absoluteURLForPathRelativeToZincFolder:(NSString *)path isDirectory:(BOOL)isDirectory {
    NSURL *docDirURL = [self urlForSearchPathDirectory:NSDocumentDirectory];
    NSURL *zincDirURL = [docDirURL URLByAppendingPathComponent:@"zinc"];
    NSURL *url = [zincDirURL URLByAppendingPathComponent:path
                                             isDirectory:isDirectory];
    NSParameterAssert(url);
    return url;

}

- (NSURL *)bundlesFolderURL {
    return [self absoluteURLForPathRelativeToZincFolder:@"bundles" isDirectory:YES];
}

- (NSURL *)manifestsFolderURL {
    return [self absoluteURLForPathRelativeToZincFolder:@"manifests" isDirectory:YES];
}

- (NSURL *)manifestURLForManifestName:(NSString *)manifestName {
    return [[self manifestsFolderURL] URLByAppendingPathComponent:manifestName
                                                         isDirectory:NO];
}

- (NSString *)manifestNameForBundleName:(NSString *)bundleName {
    return [bundleName stringByAppendingString:@".json"];
}

#pragma mark - File Size

- (unsigned long long int)sizeOfFolderInBytesWithPath:(NSString *)folderPath {
    NSError *error = nil;
    NSArray *filesArray = [NSFileManager.defaultManager subpathsOfDirectoryAtPath:folderPath error:nil];
    NSAssert(error == nil,
             @"Error while getting folder subpaths: %@ \nfor folder path:",
             error.localizedDescription,
             folderPath);

    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long int totalSize = 0;

    while (fileName = [filesEnumerator nextObject]) {
        NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
        NSDictionary *fileDictionary = [NSFileManager.defaultManager attributesOfItemAtPath:filePath error:nil];
        totalSize += [fileDictionary fileSize];
    }

    return totalSize;
}

- (CGFloat)megabytesForBytes:(unsigned long long)bytes {
    return bytes / 1024.f / 1024.f;
}

- (unsigned long long)totalSizeInBytesOfBundlesWithPrefix:(NSString *)prefix {
    __block unsigned long long size = 0;

    [self forBundlesWithPrefix:prefix performBlock:^(NSURL *bundleURL) {
        size += [self sizeOfFolderInBytesWithPath:bundleURL.path];
    }];

    return size;
}

- (CGFloat)totalSizeInMegabytesOfBundlesWithPrefix:(NSString *)prefix {
    unsigned long long bytes = [self totalSizeInBytesOfBundlesWithPrefix:prefix];
    return [self megabytesForBytes:bytes];
}

- (CGFloat)totalSizeOfContentBundles {
    return [self totalSizeInMegabytesOfBundlesWithPrefix:kContentBundlePrefix];
}

#pragma mark - Misc Private Methods

- (NSString *)bundleNameForBundleURL:(NSURL *)bundleURL {
    return [[bundleURL absoluteString] lastPathComponent];
}

- (void)forBundlesWithPrefix:(NSString *)prefix
                   performBlock:(void (^ _Nonnull)(NSURL * bundleURL))block {
    NSParameterAssert(prefix);
    NSParameterAssert(block);

    NSURL *bundlesFolderURL = [self bundlesFolderURL];

    NSError *error = nil;
    NSArray<NSURL *> *bundleURLs = [NSFileManager.defaultManager contentsOfDirectoryAtURL:bundlesFolderURL
                                                               includingPropertiesForKeys:nil
                                                                                  options:0
                                                                                    error:nil];
    NSAssert(error == nil,
             @"Error while getting bundle URLs: %@ \nfor bundle folder path:",
             error.localizedDescription,
             bundlesFolderURL.path);

    for (NSURL *bundleURL in bundleURLs) {
        NSString *bundleName = [self bundleNameForBundleURL:bundleURL];
        if ([bundleName hasPrefix:prefix]) {
            block(bundleURL);
        }
    }
}

// Example content bundle name: @"com.wonder.content4.sat-BELLY-0355-1"
// Example content bundle id: @"com.wonder.content4.sat-BELLY-0355"
- (NSString *)contentBundleIDForContentBundleName:(NSString *)bundleName {
    NSString *contentBundleRegexPattern = @"\\A(com\\.wonder\\.content\\d*\\..*)-(.*)\\Z";

    NSError *error;
    NSRegularExpression *contentBundleRegex = [NSRegularExpression regularExpressionWithPattern:contentBundleRegexPattern
                                                                                        options:NSRegularExpressionAnchorsMatchLines
                                                                                          error:&error];
    NSAssert(error == nil, @"error when creating content bundle regex: %@", error);

    NSTextCheckingResult *match = [contentBundleRegex firstMatchInString:bundleName
                                                                 options:NSMatchingAnchored
                                                                   range:NSMakeRange(0, bundleName.length)];
    NSParameterAssert(match);

    NSString *bundleID = [bundleName substringWithRange:[match rangeAtIndex:1]]; // e.g. "com.wonder.content4.sat-BELLY-0355"
    NSString *zincVersionString = [bundleName substringWithRange:[match rangeAtIndex:2]]; // e.g. "1"
    NSParameterAssert(bundleID);
    NSParameterAssert(zincVersionString);

    return bundleID;
}

- (BOOL)deleteFileAtURL:(NSURL *)url {
    NSError *error;
    [NSFileManager.defaultManager removeItemAtURL:url error:&error];
    if (error) {
        NSLog(@"Error while deleting file at url: %@ \nfor file path: %@",
              error.localizedDescription,
              url.path);
    }

    return !error;
}

@end
