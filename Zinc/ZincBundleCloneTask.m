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
    [self addEvent:[ZincBundleCloneBeginEvent bundleCloneBeginEventForBundleResource:self.resource source:self context:self.bundleId]];
}

- (void) completeWithSuccess:(BOOL)success
{
    if (success) {
        [self.repo registerBundle:self.resource status:ZincBundleStateAvailable];
    } else {
        [self.repo registerBundle:self.resource status:ZincBundleStateNone];
    }

    [self addEvent:[ZincBundleCloneCompleteEvent bundleCloneCompleteEventForBundleResource:self.resource source:self context:self.bundleId success:success]];
    
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
            [self addEvent:[ZincErrorEvent eventWithError:AMErrorAddOriginToError(error) source:self]];
            return NO;
        }
    }
    
    NSString* zincRepoPath = [[self.repo url] path];
    
    // Link files
    for (NSString* file in allFiles) {
        
        @autoreleasepool {
            
            NSString* filePath = [bundlePath stringByAppendingPathComponent:file];
            NSString* filePathDest = [self.fileManager destinationOfSymbolicLinkAtPath:filePath error:&error];
            BOOL filePathDestDoesNotExist = (filePathDest == nil);
            
            NSString* shaPath = [self.repo pathForFileWithSHA:[manifest shaForFile:file]];
            NSString* shaPathDest = [self.fileManager destinationOfSymbolicLinkAtPath:shaPath error:NULL];
            
            // if it's nil, it's not a symbolic link. use the original file.
            
            // if it is a symbolic link, which means it's linked to inside the app bundle
            // use a new symlink from the bundles dir to sha-based object - RELATIVE
            // otherwise, hard link directly to the sha-object
            BOOL useSymbolicLink = shaPathDest != nil;
            
            BOOL filePathDestCorrect = [filePathDest isEqualToString:shaPath];
            BOOL createLink = filePathDestDoesNotExist || !filePathDestCorrect;
            
            if (createLink) {
                // remove regardless and ignore errors. there are too many cases to
                // handle cleanly, with non-existant files, symlinks, etc. if something
                // fails it will be caught in the linkItemAtPath call below.
                [self.fileManager removeItemAtPath:filePath error:NULL];
                
                if (useSymbolicLink) {
                    
                    NSString* filePathRelativeToRepo = [filePath substringFromIndex:[zincRepoPath length]+1]; // +1 to remove '/'
                    NSString* shaPathRelativeToRepo = [shaPath substringFromIndex:[zincRepoPath length]+1];  // +1 to remove '/'
                    
                    NSArray* comps = [filePathRelativeToRepo pathComponents];
                    NSString* shaPathRelativeToFile = shaPathRelativeToRepo;
                    
                    for (NSUInteger i=0; i<[comps count]-1; i++) {
                        shaPathRelativeToFile = [@"../" stringByAppendingString:shaPathRelativeToFile];
                    }
                    
                    if (![self.fileManager createSymbolicLinkAtPath:filePath withDestinationPath:shaPathRelativeToFile error:&error]) {
                        [self addEvent:[ZincErrorEvent eventWithError:AMErrorAddOriginToError(error) source:self]];
                        return NO;
                    }
                    
                } else {
                    
                    if (![self.fileManager linkItemAtPath:shaPath toPath:filePath error:&error]) {
                        [self addEvent:[ZincErrorEvent eventWithError:AMErrorAddOriginToError(error) source:self]];
                        return NO;
                    }
                }
            }
        }
    }
    return YES;
}

@end
