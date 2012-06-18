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
#import "ZincObjectDownloadTask.h"
#import "ZincArchiveDownloadTask.h"
#import "ZincResource.h"
#import "ZincErrors.h"

@interface ZincBundleCloneTask ()
@property (assign) NSInteger totalBytesToDownload;
@property (retain) NSFileManager* fileManager;
@end

@implementation ZincBundleCloneTask

@synthesize httpOverheadConstant = _httpOverheadConstant;
@synthesize totalBytesToDownload = _totalBytesToDownload;
@synthesize fileManager = _fileManager;

- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input
{
    self = [super initWithRepo:repo resourceDescriptor:resource input:input];
    if (self) {
        _httpOverheadConstant = kZincBundleCloneTaskDefaultHTTPOverheadConstant;
    }
    return self;
}

- (void)dealloc
{
    [_fileManager release];
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

- (double) downloadCostForTotalSize:(NSUInteger)totalSize connectionCount:(NSUInteger)connectionCount
{
    return (double)self.httpOverheadConstant * connectionCount + totalSize;
}

- (BOOL) prepareManifest
{
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
            return NO;
        }
    }
    return YES;
}

- (BOOL) prepareObjectFilesUsingRemoteCatalogForManifest:(ZincManifest*)manifest
{
    NSUInteger totalSize = 0;
    NSUInteger missingSize = 0;
    
    NSArray* allFiles = [manifest allFiles];
    NSMutableArray* missingFiles = [NSMutableArray arrayWithCapacity:[allFiles count]];
    
    for (NSString* path in allFiles) {
        
        NSString* format = [manifest bestFormatForFile:path];
        if (format == nil) {
            [self addEvent:[ZincErrorEvent eventWithError:ZincError(ZINC_ERR_INVALID_FORMAT) source:self]];
            return NO;
        }
        
        NSUInteger size = [manifest sizeForFile:path format:format];
        totalSize += size;
        if (![self.repo hasFileWithSHA:[manifest shaForFile:path]]) {
            missingSize += size;
            [missingFiles addObject:path];
        }
    }
    
    if (missingSize > 0) {
        
        self.totalBytesToDownload = missingSize;
        
        double filesCost = [self downloadCostForTotalSize:missingSize connectionCount:[missingFiles count]];
        double archiveCost = [self downloadCostForTotalSize:totalSize connectionCount:1];
        
        if ([missingFiles count] > 1 && archiveCost < filesCost) { // ARCHIVE MODE
            
            NSURL* bundleRes = [NSURL zincResourceForArchiveWithId:self.bundleId version:self.version];
            ZincTaskDescriptor* archiveTaskDesc = [ZincArchiveDownloadTask taskDescriptorForResource:bundleRes];
            ZincTask* archiveOp = [self queueSubtaskForDescriptor:archiveTaskDesc input:nil];
            
            [archiveOp waitUntilFinished];
            if (!archiveOp.finishedSuccessfully) {
                return NO;
            }
            
        } else { // INVIDIDUAL FILE MODE
            
            NSString* catalogId = [ZincBundle catalogIdFromBundleId:self.bundleId];
            NSArray* files = [manifest allFiles];
            NSMutableArray* fileOps = [NSMutableArray arrayWithCapacity:[files count]];
            
            for (NSString* file in missingFiles) {
                
                NSString* sha = [manifest shaForFile:file];
                NSArray* formats = [manifest formatsForFile:file];
                
                NSURL* fileRes = [NSURL zincResourceForObjectWithSHA:sha inCatalogId:catalogId];
                ZincTaskDescriptor* fileTaskDesc = [ZincObjectDownloadTask taskDescriptorForResource:fileRes];
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
            
            if (!allSuccessful) return NO;
        }
    }
    return YES;
}

- (BOOL) prepareObjectFilesUsingMainBundleForManifest:(ZincManifest*)manifest
{
    NSError* error = nil;
    
    // make sha-based links in the repo to files inside the main bundle
    NSArray* allFiles = [manifest allFiles];    
    for (NSString* file in allFiles) {
        NSString* sha = [manifest shaForFile:file];
        NSString* srcPath = [[NSBundle mainBundle] pathForResource:file ofType:nil];
        NSString* dstPath = [self.repo pathForFileWithSHA:sha];
        if (![self.fileManager fileExistsAtPath:dstPath]) {
            if (![self.fileManager createSymbolicLinkAtPath:dstPath withDestinationPath:srcPath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL) createBundleLinksForManifest:(ZincManifest*)manifest
{
    NSError* error = nil;
    
    NSArray* allFiles = [manifest allFiles];
    NSString* bundlePath = [self.repo pathForBundleWithId:self.bundleId version:self.version];
    for (NSString* file in allFiles) {
        NSString* filePath = [bundlePath stringByAppendingPathComponent:file];
        NSString* fileDir = [filePath stringByDeletingLastPathComponent];
        if (![self.fileManager zinc_createDirectoryIfNeededAtPath:fileDir error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            return NO;
        }
        
        NSString* shaPath = [self.repo pathForFileWithSHA:[manifest shaForFile:file]];
        BOOL createLink = NO;
        if ([self.fileManager fileExistsAtPath:filePath]) {
            NSString* dst = [self.fileManager destinationOfSymbolicLinkAtPath:filePath error:NULL];
            if (![dst isEqualToString:shaPath]) {
                if (![self.fileManager removeItemAtPath:filePath error:&error]) {
                    [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                    return NO;
                }
                createLink = YES;
            }
        } else {
            createLink = YES;
        }
        
        if (createLink) {
            if (![self.fileManager linkItemAtPath:shaPath toPath:filePath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                return NO;
            }
        }
    }
    return YES;
}

- (void) main
{
    [self addEvent:[ZincBundleCloneBeginEvent bundleCloneBeginEventForBundleResource:self.resource]];
    
    NSError* error = nil;
    self.fileManager = [[[NSFileManager alloc] init] autorelease];
    
    if (![self prepareManifest]) {
        return;
    }
    
    ZincManifest* manifest = [self.repo manifestWithBundleId:self.bundleId version:self.version error:&error];
    if (manifest == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    BOOL cloneLocal = [[self.repo.index localBundles] containsObject:self.resource];
    if (cloneLocal) {
        if (![self prepareObjectFilesUsingMainBundleForManifest:manifest]) {
            return;
        }

    } else {
        if (![self prepareObjectFilesUsingRemoteCatalogForManifest:manifest]) {
            return;
        }
    }
    
    if (![self createBundleLinksForManifest:manifest]) {
        return;
    }
    
    [self.repo registerBundle:self.resource status:ZincBundleStateAvailable];
    
    [self addEvent:[ZincBundleCloneCompleteEvent bundleCloneCompleteEventForBundleResource:self.resource context:self.bundleId]];
    
    self.finishedSuccessfully = YES;
}

@end
