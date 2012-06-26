//
//  ZincBundleBootstrapTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 6/19/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleBootstrapTask.h"
#import "ZincBundleCloneTask+Private.h"
#import "ZincManifest.h"
#import "ZincKSJSON.h"
#import "ZincRepo+Private.h"
#import "ZincEvent.h"
#import "ZincErrors.h"
#import "ZincResource.h"

@implementation ZincBundleBootstrapTask

- (ZincManifest*) importManifestWithPath:(NSString*)manifestPath error:(NSError**)outError
{
    NSString* jsonString = [NSString stringWithContentsOfFile:manifestPath encoding:NSUTF8StringEncoding error:outError];
    if (jsonString == nil) {
        return nil;
    }
    
    // copy manifest to repo
    NSDictionary* manifestDict = [ZincKSJSON deserializeString:jsonString error:outError];
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
    
    // make sha-based links in the repo to files inside the main bundle
    NSArray* allFiles = [manifest allFiles];    
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
    if (![self prepareObjectFileWithManifest:manifest fileRootPath:fileRootPath]) {
        return;
    }

    if (![self createBundleLinksForManifest:manifest]) {
        return;
    }
    
    [self complete];
}

@end
