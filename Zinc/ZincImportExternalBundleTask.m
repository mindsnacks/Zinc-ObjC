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
