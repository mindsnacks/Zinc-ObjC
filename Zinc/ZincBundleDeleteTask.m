//
//  ZincBundleDeleteTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleDeleteTask.h"
#import "ZincTask+Private.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincEvent.h"
#import "ZincManifest.h"
#import "ZincResource.h"
#import "ZincTaskActions.h"
#import "NSError+Zinc.h"
#import "NSFileManager+Zinc.h"

@implementation ZincBundleDeleteTask

+ (NSString *)action
{
    return ZincTaskActionDelete;
}

- (void)dealloc
{
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

- (void) main
{
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];

    if (![self.repo hasManifestForBundleIdentifier:self.bundleId version:self.version]) {
        // exit early
        [self.repo deregisterBundle:self.resource];
        self.finishedSuccessfully = YES;
        return;
    }

    ZincManifest* manifest = [self.repo manifestWithBundleId:self.bundleId version:self.version error:&error];
    if (manifest == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    NSString* bundlePath = [self.repo pathForBundleWithId:self.bundleId version:self.version];
    
#if 0
    // this is cleaner, but crashes: http://openradar.appspot.com/9536091
    NSDirectoryEnumerator* dirEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:bundlePath]
                              includingPropertiesForKeys:[NSArray arrayWithObjects:
                                                          NSURLIsRegularFileKey,
                                                          NSURLLinkCountKey, nil]
                                                 options:0 
                                            errorHandler:^(NSURL* url, NSError* error){
                                                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                                                return YES;
                                            }];

    // to turn an absolute bundle path into a bundle relative path
    NSInteger bundleFileTrimLength = [bundlePath length] + 1;

    // first pass, scan to find any shared sha-based files to delete
    for (NSURL *theURL in dirEnum) {
        
        NSNumber *isRegularFile;
        if (![theURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            continue;
        }
        
        if ([isRegularFile boolValue]) {
            
            NSNumber *linkCount;
            if (![theURL getResourceValue:&linkCount forKey:NSURLLinkCountKey error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                continue;
            }

            // check the link count. if it's 2, it means the only links are the
            // one in this bundle, and the original in files/<sha>
            if ([linkCount integerValue] == 2) {
                
                NSString* absPath = [[theURL absoluteURL] path];
                NSString* relPath = [absPath substringFromIndex:bundleFileTrimLength];
                NSString* sha = [manifest shaForFile:relPath];
                NSString* shaPath = [self.repo pathForFileWithSHA:sha];
                
                if (shaPath != nil) {
                    ZINC_DEBUG_LOG(@"REMOVING %@", shaPath);
                    if (![fm removeItemAtPath:shaPath error:&error]) {
                        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                        continue;
                    }
                }
            }
        }
    }
    
#endif
    
    // remove the bundle dir
    if (![fm zinc_removeItemAtPath:bundlePath error:&error]) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    } else {
        [self addEvent:[ZincDeleteEvent deleteEventForPath:bundlePath source:self]];
    }
    
    NSString* flavor = [self.repo.index trackedFlavorForBundleId:self.bundleId];
    NSArray* pathsForFlavor = [manifest filesForFlavor:flavor];
    
    // scan for sha-based objects to remove

    for (NSString* path in pathsForFlavor) {
        
        NSString* sha = [manifest shaForFile:path];
        NSString* shaPath = [self.repo pathForFileWithSHA:sha];

        // see notes below
        NSDictionary* attr = [fm attributesOfItemAtPath:shaPath error:&error];
        if (attr == nil) {
            if (![error zinc_isFileNotFoundError]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            }
            continue;
        }
        
        // don't delete _symbolic_ links, and only delete hard-linked files if
        // their reference count is 1
        
        NSNumber* linkCount = [attr objectForKey:NSFileReferenceCount];
        NSString* type = [attr objectForKey:NSFileType];
        
        BOOL shouldDeleteFile = ![type isEqualToString:NSFileTypeSymbolicLink]
                                    && [linkCount integerValue] == 1;
        
        if (shouldDeleteFile) {
            if (![fm zinc_removeItemAtPath:shaPath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                continue;
            } else {
                [self addEvent:[ZincDeleteEvent deleteEventForPath:shaPath source:self]];
            }
        }
    }
    
    // finally remove the manifest
    if(![self.repo removeManifestForBundleId:self.bundleId version:self.version error:&error]) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    } else {
        // kinda odd to ask for the path after deleting, but thats how the API works ATM
        NSString* bundlePath = [self.repo pathForManifestWithBundleId:self.bundleId version:self.version];
        [self addEvent:[ZincDeleteEvent deleteEventForPath:bundlePath source:self]];
    }
    
    [self.repo deregisterBundle:self.resource];

    self.finishedSuccessfully = YES;
}

@end


/*
 Relevant attributes for SYMLINKS
{
    NSFileReferenceCount = 1;
    NSFileType = NSFileTypeSymbolicLink;
}
 */
