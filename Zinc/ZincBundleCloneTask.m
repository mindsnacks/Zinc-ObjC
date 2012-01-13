//
//  ZincBundleUpdateOperation.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleCloneTask.h"
#import "ZincRepo+Private.h"
#import "ZincManifest.h"
#import "ZincManifestDownloadTask.h"
#import "ZincEvent.h"
#import "NSFileManager+Zinc.h"
#import "ZincFileDownloadTask.h"
#import "ZincResource.h"

@implementation ZincBundleCloneTask

@synthesize bundleId = _bundleId;
@synthesize version = _version;

- (id)initWithRepo:(ZincRepo *)repo bundleId:(NSString*)bundleId version:(ZincVersion)version;
{
    NSURL* res = [NSURL zincResourceForBundleWithId:bundleId version:version];
    self = [super initWithRepo:repo resourceDescriptor:res];
    if (self) {
        self.bundleId = bundleId;
        self.version = version;
    }
    return self;
}

- (void)dealloc
{
    self.bundleId = nil;
    [super dealloc];
}

- (void) main
{
    ZINC_DEBUG_LOG(@"CLONING BUNDLE %@!", self.bundleId);
    
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    
    ZincManifestDownloadTask* manifestOp = nil;
    
    // if the manifest doesn't exist, get it. 
    if (![self.repo hasManifestForBundleIdentifier:self.bundleId version:self.version]) {
        manifestOp = [[[ZincManifestDownloadTask alloc] initWithRepo:self.repo bundleId:self.bundleId version:self.version] autorelease];
        manifestOp = (ZincManifestDownloadTask*)[self.repo getOrAddTask:manifestOp];
    }
    
    if (manifestOp != nil) {
        [manifestOp waitUntilFinished];
        if (!manifestOp.finishedSuccessfully) {
            // TODO: add events?
            return;
        }
    }
    
    ZincManifest* manifest = [self.repo manifestWithBundleIdentifier:self.bundleId version:self.version error:&error];
    if (manifest == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    NSString* catalogId = [ZincBundle catalogIdFromBundleId:self.bundleId];
    NSArray* sources = [self.repo sourcesForCatalogId:catalogId];
    if (sources == nil || [sources count] == 0) {
        // TODO: error, log, or requeue or SOMETHING
        return;
    }
    
    NSArray* SHAs = [manifest allSHAs];
    NSMutableArray* fileOps = [NSMutableArray arrayWithCapacity:[SHAs count]];
    
    for (NSString* sha in SHAs) {
        NSString* path = [self.repo pathForFileWithSHA:sha];
        
        // check if file is missing
        if (![fm fileExistsAtPath:path]) {
            
            // queue redownload
            ZincSource* source = [sources lastObject]; // TODO: fix lastobject
            NSAssert(source, @"source is nil");
            ZincTask* fileOp = 
            [[[ZincFileDownloadTask alloc] initWithRepo:self.repo
                                               source:source
                                                  sha:sha] autorelease];
            fileOp = [self.repo getOrAddTask:fileOp];
            [fileOps addObject:fileOp];
        }
    }
    
    
    BOOL allSuccessful = YES;
    
    for (ZincTask* op in fileOps) {
        [op waitUntilFinished];
        if (!op.finishedSuccessfully) {
            allSuccessful = NO;
        }
    }
    
    if (!allSuccessful) return;
    
    NSString* bundlePath = [self.repo pathForBundleWithId:self.bundleId version:self.version];
    NSArray* allFiles = [manifest allFiles];
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
    
    ZINC_DEBUG_LOG(@"FINISHED BUNDLE %@!", self.bundleId);
    
    [self.repo registerBundle:self.resource];
    
    self.finishedSuccessfully = YES;
}

@end
