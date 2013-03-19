//
//  ZincBundleCloneTask.m
//
//
//  Created by Andy Mroczkowski on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZincBundleCloneTask.h"
#import "ZincTask+Private.h"
#import "ZincBundleCloneTask+Private.h"
#import "NSFileManager+Zinc.h"
#import "ZincResource.h"
#import "ZincEvent.h"
#import "ZincRepo+Private.h"
#import "ZincManifest.h"
#import "ZincTaskActions.h"

@implementation ZincBundleCloneTask

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

- (NSString*) getTrackedFlavor
{
    return [self.repo.index trackedFlavorForBundleId:self.bundleId];
}

- (void) setUp
{
    self.fileManager = [[[NSFileManager alloc] init] autorelease];
    [self addEvent:[ZincBundleCloneBeginEvent bundleCloneBeginEventForBundleResource:self.resource source:ZINC_EVENT_SRC() context:self.bundleId]];
}

- (void) completeWithSuccess:(BOOL)success
{
    if (success) {
        [self.repo registerBundle:self.resource status:ZincBundleStateAvailable];
    } else {
        [self.repo registerBundle:self.resource status:ZincBundleStateNone];
    }

    [self addEvent:[ZincBundleCloneCompleteEvent bundleCloneCompleteEventForBundleResource:self.resource source:ZINC_EVENT_SRC() context:self.bundleId success:success]];
    
    self.finishedSuccessfully = success;
}

- (BOOL) createBundleLinksForManifest:(ZincManifest*)manifest
{
    NSError* error = nil;
    
    NSString* flavor = [self getTrackedFlavor];
    
    NSString* bundlePath = [self.repo pathForBundleWithId:self.bundleId version:self.version];
    NSArray* allFiles = [manifest filesForFlavor:flavor];
    
    // Build a list of all dirs needed for the bundle
    NSMutableSet* allDirs = [NSMutableSet setWithCapacity:[allFiles count]];
    for (NSString* file in allFiles) {
        NSString* dir = [file stringByDeletingLastPathComponent];
        [allDirs addObject:dir];
    }
    
    // Create all dirs
    for (NSString* relativeDir in allDirs) {
        NSString* fullDir = [bundlePath stringByAppendingPathComponent:relativeDir];
        if (![self.fileManager zinc_createDirectoryIfNeededAtPath:fullDir error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:AMErrorAddOriginToError(error) source:ZINC_EVENT_SRC()]];
            return NO;
        }
    }
    
    // Link files
    for (NSString* file in allFiles) {
        @autoreleasepool {
            NSString* filePath = [bundlePath stringByAppendingPathComponent:file];
            const BOOL createLink = ![self.fileManager fileExistsAtPath:filePath];
            if (createLink) {
                NSString* shaPath = [self.repo pathForFileWithSHA:[manifest shaForFile:file]];
                if (![self.fileManager linkItemAtPath:shaPath toPath:filePath error:&error]) {
                    [self addEvent:[ZincErrorEvent eventWithError:AMErrorAddOriginToError(error) source:ZINC_EVENT_SRC()]];
                    return NO;
                }
            }
        }
    }
    return YES;
}

@end
