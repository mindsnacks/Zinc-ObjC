//
//  ZincBundleUpdateOperation.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleCloneTask+Private.h"

#import "ZincInternals.h"
#import "ZincTask+Private.h"
#import "ZincRepo+Private.h"
#import "ZincCreateBundleLinksOperation.h"

@interface ZincBundleRemoteCloneTask ()
@property (strong) NSArray* downloadTasks;
@end

@implementation ZincBundleRemoteCloneTask

- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input
{
    self = [super initWithRepo:repo resourceDescriptor:resource input:input];
    if (self) {
        _httpOverheadConstant = kZincBundleCloneTaskDefaultHTTPOverheadConstant;

        __weak typeof(self) weakself = self;
        self.readinessBlock = ^{
            typeof(self) strongself = weakself;
            return [strongself.repo doesPolicyAllowDownloadForBundleID:strongself.bundleID];
        };
    }
    return self;
}

- (double) downloadCostForTotalSize:(NSUInteger)totalSize connectionCount:(NSUInteger)connectionCount
{
    return (double)self.httpOverheadConstant * connectionCount + totalSize;
}

- (long long) currentProgressValue
{
    if (self.downloadTasks == nil) {
        return ZincProgressNotYetDetermined;
    }
    return [super currentProgressValue];
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

- (NSArray*) buildTasksForDownloadingArchive
{
    NSURL* bundleRes = [NSURL zincResourceForArchiveWithId:self.bundleID version:self.version];
    ZincTaskDescriptor* archiveTaskDesc = [ZincArchiveDownloadTask taskDescriptorForResource:bundleRes];
    ZincTask* archiveOp = [self queueChildTaskForDescriptor:archiveTaskDesc input:[self getTrackedFlavor]];

    return [NSArray arrayWithObject:archiveOp];
}

- (NSArray*) buildTasksForDownloadUsingIndividualFilesWithManifest:(ZincManifest*)manifest missingFiles:(NSArray*)missingFiles
{
    NSString* catalogID = ZincCatalogIDFromBundleID(self.bundleID);
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
    return fileOps;
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

    // Create the link operation and add it as a child so it's
    // progress is account into the total progress
    ZincCreateBundleLinksOperation* linkOp = [[ZincCreateBundleLinksOperation alloc] initWithRepo:self.repo manifest:manifest];
    [self addChildOperation:linkOp];

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
    
    BOOL downloadedAllFilesSuccessfully = YES;

    if (missingSize > 0) {
        
        const double filesCost = [self downloadCostForTotalSize:missingSize connectionCount:[missingFiles count]];
        const double archiveCost = [self downloadCostForTotalSize:totalSize connectionCount:1];
        const BOOL shouldDownloadArchive = ([missingFiles count] > 1 && archiveCost < filesCost);

        if (shouldDownloadArchive) {
            self.downloadTasks = [self buildTasksForDownloadingArchive];
        } else {
            self.downloadTasks = [self buildTasksForDownloadUsingIndividualFilesWithManifest:manifest missingFiles:missingFiles];
        }
        
    } else {
        self.downloadTasks = @[];
    }

    for (ZincTask* task in self.downloadTasks) {

        [task waitUntilFinished];
        if (self.isCancelled) return NO;
        downloadedAllFilesSuccessfully &= task.finishedSuccessfully;
    }

    if (downloadedAllFilesSuccessfully) {
        [self queueChildOperation:linkOp];
        [linkOp waitUntilFinished];
    }

    return downloadedAllFilesSuccessfully && [linkOp isSuccessful];
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
        [self addEvent:[ZincErrorEvent eventWithError:AMErrorWrap(error) source:ZINC_EVENT_SRC()]];
        [self completeWithSuccess:NO];
        return;
    }
    
    if (![self prepareObjectFilesUsingRemoteCatalogForManifest:manifest]) {
        [self completeWithSuccess:NO];
        return;
    }

    [self completeWithSuccess:YES];
}

@end
