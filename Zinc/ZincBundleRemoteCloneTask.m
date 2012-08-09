//
//  ZincBundleUpdateOperation.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleRemoteCloneTask.h"
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
@property (assign) NSInteger totalBytesToDownload;
@property (assign) NSInteger lastProgressValue;
@end

@implementation ZincBundleRemoteCloneTask

@synthesize httpOverheadConstant = _httpOverheadConstant;
@synthesize totalBytesToDownload = _totalBytesToDownload;

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
    return self.totalBytesToDownload > 0;
}

- (NSInteger) currentProgressValue
{
    if (![self isProgressCalculated]) return 0;
    
    NSInteger curVal = [super currentProgressValue];
    if (curVal < self.lastProgressValue) {
        curVal = self.lastProgressValue;
    } else if (curVal > [self maxProgressValue]) {
        curVal = [self maxProgressValue];
    }
    self.lastProgressValue = curVal;
    return curVal;
}

- (NSInteger) maxProgressValue
{
    return self.totalBytesToDownload;
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
    
    NSString* flavor = [self getTrackedFlavor];
    
    NSArray* allFiles = [manifest filesForFlavor:flavor];
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

- (void) main
{
    [self setUp];
    
    NSError* error = nil;
    
    if (![self prepareManifest]) {
        return;
    }
    
    ZincManifest* manifest = [self.repo manifestWithBundleId:self.bundleId version:self.version error:&error];
    if (manifest == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    if (![self prepareObjectFilesUsingRemoteCatalogForManifest:manifest]) {
        return;
    }
    
    if (![self createBundleLinksForManifest:manifest]) {
        return;
    }
    
    [self complete];
}

@end
