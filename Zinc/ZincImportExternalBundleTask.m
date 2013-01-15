//
//  ZincImportExternalBundleTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 10/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincImportExternalBundleTask.h"
#import "ZincTask+Private.h"
#import "ZincTaskActions.h"
#import "ZincResource.h"
#import "ZincManifest.h"
#import "ZincEvent.h"
#import "ZincRepo+Private.h"

@interface ZincImportExternalBundleTask ()
@property (retain) NSFileManager* fileManager;
@end

@implementation ZincImportExternalBundleTask

@synthesize fileManager = _fileManager;

+ (NSString *)action
{
    return ZincTaskActionUpdate;
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

- (BOOL) prepareObjectFileWithManifest:(ZincManifest*)manifest fileRootPath:(NSString*)fileRootPath
{
    NSError* error = nil;
    
    NSString* flavor = [self.repo.index trackedFlavorForBundleId:self.bundleId];
    
    // make sha-based links in the repo to files inside the main bundle
    NSArray* allFiles = [manifest filesForFlavor:flavor];
    for (NSString* file in allFiles) {
        NSString* sha = [manifest shaForFile:file];
        NSString* filePath = [fileRootPath stringByAppendingPathComponent:file];
        NSString* shaPath = [self.repo pathForFileWithSHA:sha];
        
        const BOOL fileExists = [self.fileManager fileExistsAtPath:shaPath];
        
        // TODO: I don't think we need this because it's handled in garbage collect
        
//        // Special case to deal with legacy symlinks
//        const BOOL isSymlink = fileExists && ([self.fileManager destinationOfSymbolicLinkAtPath:shaPath error:NULL] != nil);
//        if (isSymlink) {
//            [self.fileManager removeItemAtPath:shaPath error:NULL];
//        }
//        
//        const BOOL shouldCopy = !fileExists || isSymlink;
        
        const BOOL shouldCopy = !fileExists;
        if (shouldCopy) {
            
            if (![self.fileManager copyItemAtPath:filePath toPath:shaPath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                return NO;
            }
        }
    }
    return YES;
}

- (void) main
{
    self.fileManager = [[[NSFileManager alloc] init] autorelease];
    
    NSError* error = nil;
    
    ZincManifest* manifest = [self.repo manifestWithBundleId:self.bundleId version:self.version error:&error];
    if (manifest == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    NSString* fileRootPath = [self.repo pathForBundleWithId:self.bundleId version:self.version];
    
    if (![self prepareObjectFileWithManifest:manifest fileRootPath:fileRootPath]) {
        return;
    }
    
    self.finishedSuccessfully = YES;
}


@end
