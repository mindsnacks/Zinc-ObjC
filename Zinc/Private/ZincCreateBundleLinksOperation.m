//
//  ZincCreateBundleLinksOperation.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/14/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincCreateBundleLinksOperation.h"

#import "ZincOperation+Private.h"
#import "ZincRepo+Private.h"
#import "ZincTask+Private.h"
#import "ZincEvent+Private.h"
#import "ZincManifest.h"
#import "NSFileManager+Zinc.h"

@interface ZincCreateBundleLinksOperation ()
@property (nonatomic, weak, readwrite) ZincRepo* repo;
@property (nonatomic, strong, readwrite) ZincManifest* manifest;
@property (nonatomic, strong, readwrite) NSError* error;
@property (nonatomic, assign, readwrite) NSUInteger linkedFileCount;
@end

#define FILE_COST (10000)

@implementation ZincCreateBundleLinksOperation

- (id) initWithRepo:(ZincRepo*)repo manifest:(ZincManifest*)manifest
{
    self = [super init];
    if (self) {
        _repo = repo;
        _manifest = manifest;
    }
    return self;
}

- (NSString*) bundleID
{
    return self.manifest.bundleID;
}

- (ZincVersion) version
{
    return self.manifest.version;
}

- (NSString*) getTrackedFlavor
{
    return [self.repo.index trackedFlavorForBundleID:self.bundleID];
}

- (NSArray*) getAllFilesToLink
{
    return [self.manifest filesForFlavor:[self getTrackedFlavor]];
}

- (long long) currentProgressValue
{
    return self.linkedFileCount * FILE_COST;
}

- (long long) maxProgressValue
{
    return [[self getAllFilesToLink] count] * FILE_COST;
}

// TODO: move into a base class? similar to ZincArchiveExtractOperation and ZincTaskRef
- (BOOL) isSuccessful
{
    return [self isFinished] && (self.error == nil);
}

- (void) main
{
    NSError* error = nil;
    NSFileManager* fm = [[NSFileManager alloc] init];

    NSArray* allFiles = [self getAllFilesToLink];
    NSString* bundlePath = [self.repo pathForBundleWithID:self.bundleID version:self.version];

    // Build a list of all dirs needed for the bundle
    NSMutableSet* allDirs = [NSMutableSet setWithCapacity:[allFiles count]];
    for (NSString* file in allFiles) {
        NSString* dir = [file stringByDeletingLastPathComponent];
        [allDirs addObject:dir];
    }

    // Create all dirs
    for (NSString* relativeDir in allDirs) {
        NSString* fullDir = [bundlePath stringByAppendingPathComponent:relativeDir];
        if (![fm zinc_createDirectoryIfNeededAtPath:fullDir error:&error]) {
            self.error = AMErrorWrap(error);
            return;
        }
    }

    // Link files
    for (NSString* file in allFiles) {
        @autoreleasepool {
            NSString* filePath = [bundlePath stringByAppendingPathComponent:file];
            const BOOL createLink = ![fm fileExistsAtPath:filePath];
            if (createLink) {
                NSString* shaPath = [self.repo pathForFileWithSHA:[self.manifest shaForFile:file]];
                if (![fm linkItemAtPath:shaPath toPath:filePath error:&error]) {
                    self.error = AMErrorWrap(error);
                    return;
                }
            }
        }
        self.linkedFileCount++;
    }
}

@end
