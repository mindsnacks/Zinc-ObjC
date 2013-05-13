//
//  ZincBundleUpdateOperation.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleRemoteCloneTask.h"
#import "ZincTask+Private.h"
#import "ZincBundleCloneTask+Private.h"
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

@interface ZincBundleRemoteCloneTask ()
@property (assign) long long maxProgressValue;
@property (assign) long long lastProgressValue;
@end

@implementation ZincBundleRemoteCloneTask

@synthesize httpOverheadConstant = _httpOverheadConstant;

- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input
{
    self = [super initWithRepo:repo resourceDescriptor:resource input:input];
    if (self) {
        _httpOverheadConstant = kZincBundleCloneTaskDefaultHTTPOverheadConstant;
    }
    return self;
}

- (double) downloadCostForTotalSize:(NSUInteger)totalSize connectionCount:(NSUInteger)connectionCount
{
    return (double)self.httpOverheadConstant * connectionCount + totalSize;
}

- (BOOL) isProgressCalculated
{
    return self.maxProgressValue > 0;
}

- (long long) currentProgressValue
{
    if (![self isProgressCalculated]) return 0;
    
    long long curVal = [super currentProgressValue];
    if (curVal < self.lastProgressValue) {
        curVal = self.lastProgressValue;
    } else if (curVal > [self maxProgressValue]) {
        curVal = [self maxProgressValue];
    }
    self.lastProgressValue = curVal;
    return curVal;
}

- (BOOL) prepareManifest
{
    ZincTask* manifestDownloadTask = nil;

    // if the manifest doesn't exist, get it. 
    if (![self.repo hasManifestForBundleIDentifier:self.bundleID version:self.version]) {
        NSURL* manifestRes = [NSURL zincResourceForManifestWithId:self.bundleID version:self.version];
        ZincTaskDescriptor* taskDesc = [ZincManifestDownloadTask taskDescriptorForResource:manifestRes];
        manifestDownloadTask = [self queueChildTaskForDescriptor:taskDesc];
    }
    
    if (manifestDownloadTask != nil) {
        
        [manifestDownloadTask waitUntilFinished];
        if (self.isCancelled) return NO;

        if (!manifestDownloadTask.finishedSuccessfully) {
            // ???: add an event?
            return NO;
        }
    }
    return YES;
}

- (BOOL) prepareObjectFilesUsingRemoteCatalogForManifest:(ZincManifest*)manifest
{
    if (self.isCancelled) return NO;
    
    NSError* error = nil;
    NSUInteger totalSize = 0;
    NSUInteger missingSize = 0;
    NSString* const flavor = [self getTrackedFlavor];
    NSArray* const allFiles = [manifest filesForFlavor:flavor];
    NSMutableArray* const missingFiles = [NSMutableArray arrayWithCapacity:[allFiles count]];
    
    for (NSString* path in allFiles) {
        
        NSString* format = [manifest bestFormatForFile:path];
        if (format == nil) {
            [self addEvent:[ZincErrorEvent eventWithError:ZincError(ZINC_ERR_INVALID_FORMAT) source:ZINC_EVENT_SRC()]];
            return NO;
        }
        
        NSUInteger size = [manifest sizeForFile:path format:format];
        totalSize += size;
        
        NSString* const sha = [manifest shaForFile:path];
        BOOL const hasFileInRepo = [self.repo hasFileWithSHA:sha];
        if (!hasFileInRepo) {
            
            NSString* localPath = [self.repo externalPathForFileWithSHA:sha];
            if (localPath != nil) {
                
                NSString* repoPath = [self.repo pathForFileWithSHA:sha];
                if ([self.fileManager copyItemAtPath:localPath toPath:repoPath error:&error]) {
                    continue;
                } else {
                    [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
                }
            }
            
            missingSize += size;
            [missingFiles addObject:path];
        }
    }
    
    if (missingSize > 0) {
        
        self.maxProgressValue = missingSize;
        
        double filesCost = [self downloadCostForTotalSize:missingSize connectionCount:[missingFiles count]];
        double archiveCost = [self downloadCostForTotalSize:totalSize connectionCount:1];
        
        if ([missingFiles count] > 1 && archiveCost < filesCost) { // ARCHIVE MODE
            
            NSURL* bundleRes = [NSURL zincResourceForArchiveWithId:self.bundleID version:self.version];
            ZincTaskDescriptor* archiveTaskDesc = [ZincArchiveDownloadTask taskDescriptorForResource:bundleRes];
            ZincTask* archiveOp = [self queueChildTaskForDescriptor:archiveTaskDesc input:[self getTrackedFlavor]];
            
            [archiveOp waitUntilFinished];
            if (self.isCancelled) return NO;

            if (!archiveOp.finishedSuccessfully) {
                return NO;
            }
            
        } else { // INVIDIDUAL FILE MODE
            
            NSString* catalogID = [ZincBundle catalogIDFromBundleID:self.bundleID];
            NSArray* files = [manifest allFiles];
            NSMutableArray* fileOps = [NSMutableArray arrayWithCapacity:[files count]];
            
            for (NSString* file in missingFiles) {
                
                NSString* sha = [manifest shaForFile:file];
                NSArray* formats = [manifest formatsForFile:file];
                
                NSURL* fileRes = [NSURL zincResourceForObjectWithSHA:sha inCatalogID:catalogID];
                ZincTaskDescriptor* fileTaskDesc = [ZincObjectDownloadTask taskDescriptorForResource:fileRes];
                
                ZincTask* fileOp = [self queueChildTaskForDescriptor:fileTaskDesc input:formats];
                if (fileOp != nil) {
                    // can be nil if cancelled
                    [fileOps addObject:fileOp];
                }
            }
            
            if (self.isCancelled) return NO;
            
            BOOL allSuccessful = YES;
            for (ZincTask* op in fileOps) {
                
                [op waitUntilFinished];
                if (self.isCancelled) return NO;
                
                if (!op.finishedSuccessfully) {
                    allSuccessful = NO;
                }
            }
            
            if (!allSuccessful) return NO;
        }
    }
    return YES;
}

- (BOOL) isReady
{
    return [super isReady] && [self.repo doesPolicyAllowDownloadForBundleID:self.bundleID];
}

- (void) main
{
    [self setUp];
    
    NSError* error = nil;
    
    if (![self prepareManifest]) {
        [self completeWithSuccess:NO];
        return;
    }
    
    ZincManifest* manifest = [self.repo manifestWithBundleID:self.bundleID version:self.version error:&error];
    if (manifest == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:AMErrorAddOriginToError(error) source:ZINC_EVENT_SRC()]];
        [self completeWithSuccess:NO];
        return;
    }
    
    if (![self prepareObjectFilesUsingRemoteCatalogForManifest:manifest]) {
        [self completeWithSuccess:NO];
        return;
    }
    
    if (![self createBundleLinksForManifest:manifest]) {
        [self completeWithSuccess:NO];
        return;
    }
    
    [self completeWithSuccess:YES];
}

@end
