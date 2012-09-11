//
//  ZincBundleBootstrapTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 6/19/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleBootstrapTask.h"
#import "ZincTask+Private.h"
#import "ZincBundleCloneTask+Private.h"
#import "ZincManifest.h"
#import "ZincJSONSerialization.h"
#import "ZincRepo+Private.h"
#import "ZincEvent.h"
#import "ZincErrors.h"
#import "ZincResource.h"
#import "ZincArchiveExtractOperation.h"

@implementation ZincBundleBootstrapTask

- (ZincManifest*) importManifestWithPath:(NSString*)manifestPath error:(NSError**)outError
{
    NSData* jsonData = [NSData dataWithContentsOfFile:manifestPath options:0 error:outError];
    if (jsonData == nil) {
        return nil;
    }

    // copy manifest to repo
    NSDictionary* manifestDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:outError];
    if (manifestDict == nil) {
        return nil;
    }

    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:manifestDict] autorelease];
    NSString* manifestRepoPath = [self.repo pathForManifestWithBundleId:manifest.bundleId version:manifest.version];

    // always remove the manifest, local versions can't be trusted
    if ([self.fileManager fileExistsAtPath:manifestRepoPath]) {
        if (![self.fileManager removeItemAtPath:manifestRepoPath error:outError]) {
            return nil;
        }
    }
            
    if (![self.fileManager copyItemAtPath:manifestPath toPath:manifestRepoPath error:outError]) {
        return nil;
    }
    
    return manifest;
}

- (BOOL) prepareObjectFileWithManifest:(ZincManifest*)manifest fileRootPath:(NSString*)fileRootPath
{
    NSError* error = nil;
    
    NSString* flavor = [self getTrackedFlavor];
    
    // make sha-based links in the repo to files inside the main bundle
    NSArray* allFiles = [manifest filesForFlavor:flavor];
    for (NSString* file in allFiles) {
        NSString* sha = [manifest shaForFile:file];
        NSString* srcPath = [fileRootPath stringByAppendingPathComponent:file];
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

- (void) main
{
    // TODO: add some way to tell it's a bootstrap? (other than version 0)
    [self setUp];
    
    NSError* error = nil;
    
    NSString* manifestPath = [[self input] valueForKey:@"manifestPath"];
    ZincManifest* manifest = [self importManifestWithPath:manifestPath error:&error];
    if (manifest == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    NSString* fileRootPath = [manifestPath stringByDeletingLastPathComponent];
    
    NSString* archivePath = [fileRootPath stringByAppendingPathComponent:
                             [self.bundleId stringByAppendingPathExtension:@"tar"]];
    
    if ([self.fileManager fileExistsAtPath:archivePath]) {
        
        ZincArchiveExtractOperation* extractOp = [[[ZincArchiveExtractOperation alloc] initWithZincRepo:self.repo archivePath:archivePath] autorelease];
        [self addOperation:extractOp];
        
        [extractOp waitUntilFinished];
        if (self.isCancelled) return;

        if (extractOp.error != nil) {
            [self addEvent:[ZincErrorEvent eventWithError:extractOp.error source:self]];
            return;
        }
        
    } else {
    
        if (![self prepareObjectFileWithManifest:manifest fileRootPath:fileRootPath]) {
            return;
        }
    }
    
    if (![self createBundleLinksForManifest:manifest]) {
        return;
    }
    
    [self complete];
}

@end
