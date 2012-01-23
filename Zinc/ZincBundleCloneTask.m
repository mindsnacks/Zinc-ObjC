//
//  ZincBundleUpdateOperation.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleCloneTask.h"
#import "ZincRepo+Private.h"
#import "ZincBundle.h"
#import "ZincManifest.h"
#import "ZincResource.h"
#import "ZincTaskDescriptor.h"
#import "ZincManifestDownloadTask.h"
#import "ZincEvent.h"
#import "NSFileManager+Zinc.h"
#import "ZincFileDownloadTask.h"
#import "ZincArchiveDownloadTask.h"
#import "ZincResource.h"
#import "ZincErrors.h"

@implementation ZincBundleCloneTask

- (void)dealloc
{
    [super dealloc];
}

- (NSString*) bundleId
{
    return [self.resource zincBundleId];
}

- (ZincVersion) version
{
    return [self.resource zincBundleVersion];
}

- (void) main
{
    [self addEvent:[ZincBundleCloneBeginEvent bundleCloneBeginEventForBundleResource:self.resource]];
    
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    
    ZincTask* manifestDownloadTask = nil;
    
    // if the manifest doesn't exist, get it. 
    if (![self.repo hasManifestForBundleIdentifier:self.bundleId version:self.version]) {
        NSURL* manifestRes = [NSURL zincResourceForManifestWithId:self.bundleId version:self.version];
        ZincTaskDescriptor* taskDesc = [ZincManifestDownloadTask taskDescriptorForResource:manifestRes];
        manifestDownloadTask = [self queueSubtaskForDescriptor:taskDesc];
    }
    
    if (manifestDownloadTask != nil) {
        [manifestDownloadTask waitUntilFinished];
        if (!manifestDownloadTask.finishedSuccessfully) {
            // ???: add an event?
            return;
        }
    }
    
    ZincManifest* manifest = [self.repo manifestWithBundleIdentifier:self.bundleId version:self.version error:&error];
    if (manifest == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    NSUInteger totalSize = 0;
    NSUInteger missingSize = 0;
    
    NSArray* allFiles = [manifest allFiles];
    NSMutableArray* missingFiles = [NSMutableArray arrayWithCapacity:[allFiles count]];
    
    for (NSString* path in allFiles) {
        
        NSString* format = [manifest bestFormatForFile:path];
        if (format == nil) {
            [self addEvent:[ZincErrorEvent eventWithError:ZincError(ZINC_ERR_INVALID_FORMAT) source:self]];
            return;
        }
        
        NSUInteger size = [manifest sizeForFile:path format:format];
        totalSize += size;
        if (![self.repo hasFileWithSHA:[manifest shaForFile:path]]) {
            missingSize += size;
            [missingFiles addObject:path];
        }
    }
    
    BOOL getAchive = ((double)missingSize / totalSize > 0.5);

    if (getAchive) { // ARCHIVE MODE
        
        NSURL* bundleRes = [NSURL zincResourceForArchiveWithId:self.bundleId version:self.version];
        ZincTaskDescriptor* archiveTaskDesc = [ZincArchiveDownloadTask taskDescriptorForResource:bundleRes];
        ZincTask* archiveOp = [self queueSubtaskForDescriptor:archiveTaskDesc input:nil];
        
        [archiveOp waitUntilFinished];
        if (!archiveOp.finishedSuccessfully) {
            return;
        }
    
    } else { // INVIDIDUAL FILE MODE
        
        NSString* catalogId = [ZincBundle catalogIdFromBundleId:self.bundleId];
        NSArray* files = [manifest allFiles];
        NSMutableArray* fileOps = [NSMutableArray arrayWithCapacity:[files count]];
        
        for (NSString* file in missingFiles) {

            NSString* sha = [manifest shaForFile:file];
            NSArray* formats = [manifest formatsForFile:file];
            
            NSURL* fileRes = [NSURL zincResourceForObjectWithSHA:sha inCatalogId:catalogId];
            ZincTaskDescriptor* fileTaskDesc = [ZincFileDownloadTask taskDescriptorForResource:fileRes];
            ZincTask* fileOp = [self queueSubtaskForDescriptor:fileTaskDesc input:formats];
            [fileOps addObject:fileOp];
        }
        
        BOOL allSuccessful = YES;
        
        for (ZincTask* op in fileOps) {
            [op waitUntilFinished];
            if (!op.finishedSuccessfully) {
                allSuccessful = NO;
            }
        }
        
        if (!allSuccessful) return;
    }
    
    NSString* bundlePath = [self.repo pathForBundleWithId:self.bundleId version:self.version];
    for (NSString* file in allFiles) {
        NSString* filePath = [bundlePath stringByAppendingPathComponent:file];
        NSString* fileDir = [filePath stringByDeletingLastPathComponent];
        if (![fm zinc_createDirectoryIfNeededAtPath:fileDir error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            return;
        }
        
        NSString* shaPath = [self.repo pathForFileWithSHA:[manifest shaForFile:file]];
        BOOL createLink = NO;
        if ([fm fileExistsAtPath:filePath]) {
            NSString* dst = [fm destinationOfSymbolicLinkAtPath:filePath error:NULL];
            if (![dst isEqualToString:shaPath]) {
                if (![fm removeItemAtPath:filePath error:&error]) {
                    [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                    return;
                }
                createLink = YES;
            }
        } else {
            createLink = YES;
        }
        
        if (createLink) {
            if (![fm linkItemAtPath:shaPath toPath:filePath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                return;
            }
        }
    }
    
    [self.repo registerBundle:self.resource status:ZincBundleStateAvailable];
    
    [self addEvent:[ZincBundleCloneCompleteEvent bundleCloneCompleteEventForBundleResource:self.resource]];
    
    self.finishedSuccessfully = YES;
}

@end
