//
//  ZincContentBundleDeleteTask.m
//  Zinc-ObjC
//
//  Created by Matthew Sun on 3/28/17.
//  Copyright © 2017 MindSnacks. All rights reserved.
//

#import "ZincContentBundleDeleteTask.h"

#import "NSData+Zinc.h"

#import <UIKit/UIKit.h>

static const CGFloat kContentBundleFlushLimitInMegabytes = -1.f;

static NSString * const kContentBundlePrefix = @"com.wonder.content";

@implementation ZincContentBundleDeleteTask

#pragma mark - ZincTask

+ (NSString *)action {
    return @"ContentBundleDelete";
}

#pragma mark - ZincMaintenanceTask

- (void)doMaintenance {
    CGFloat totalSizeOfContentBundles = [self totalSizeOfContentBundles];
    NSString *message = [NSString stringWithFormat:@"Total size of content bundles: %f", totalSizeOfContentBundles];

    if (totalSizeOfContentBundles < kContentBundleFlushLimitInMegabytes) {
        NSLog(@"%@, will not clear", message);
        return;
    }

    NSLog(@"%@, will clear", message);

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

    [NSNotificationCenter.defaultCenter postNotificationName:kZincAllContentBundlesWereDeleted
                                                      object:self
                                                    userInfo:nil];
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
        NSLog(@"Error while creating NSDictionary with json file path: %@", repoJSONPath);
        return nil;
    }

    return jsonDict;
}

/* return YES if success, NO otherwise
 */
- (BOOL)writeToRepoJSONWithJSONDict:(NSDictionary *)jsonDict {
    [self deleteFileAtURL:self.repoJSONURL];

    NSError *error;

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:0
                                                         error:&error];
    if (error) {
        NSLog(@"Failed to create NSData with json object: %@", jsonDict);
        return NO;
    }

    NSString *repoJSONPath = [self repoJSONPath];
    NSParameterAssert(repoJSONPath);
    [jsonData zinc_writeToFile:repoJSONPath
                    atomically:YES
             createDirectories:YES
                    skipBackup:NO
                         error:&error];

    NSURL *myURL = [self absoluteURLForPathRelativeToZincFolder:@"repo2.json" isDirectory:NO];
    NSLog(@"myURL: %@", myURL);
    NSString *myPath = [myURL path];
    NSLog(@"myPath: %@", myPath);

    [jsonData zinc_writeToFile:myPath
                    atomically:YES
             createDirectories:YES
                    skipBackup:NO
                         error:&error];

    if (error) {
        NSLog(@"Error while writing to file: %@", repoJSONPath);
        return NO;
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

#pragma mark - URLs

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

- (NSString *)manifestNameForBundleName:(NSString *)bundleName {
    return [bundleName stringByAppendingString:@".json"];
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
