//
//  ZincGarbageCollectTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincGarbageCollectTask.h"
#import "ZincTask+Private.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincResource.h"
#import "ZincManifest.h"
#import "ZincEvent.h"
#import "ZincTaskActions.h"

@implementation ZincGarbageCollectTask

+ (NSString *)action
{
    return ZincTaskActionUpdate;
}

- (void) cleanObjectsDir
{
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    NSDirectoryEnumerator* filesEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:[self.repo filesPath]]
                                includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsRegularFileKey, NSURLLinkCountKey, NSURLIsSymbolicLinkKey, nil]
                                                   options:0
                                              errorHandler:^(NSURL* url, NSError* error){
                                                  return YES;
                                              }];
    for (NSURL *theURL in filesEnum) {
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
            if ([linkCount integerValue] < 2) {
                [fm removeItemAtURL:theURL error:NULL];
            }
        } else {
            if (self.repo.shouldCleanSymlinks) {
                NSNumber *isSymlink;
                if (![theURL getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:&error]) {
                    [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                    continue;
                }
                if ([isSymlink boolValue]) {
                    [fm removeItemAtURL:theURL error:NULL];
                }
            }
        }
    }
}

- (void) cleanBundlesDir
{
    if (!self.repo.shouldCleanSymlinks) return;
    
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    NSString* bundlesPath = [self.repo bundlesPath];
    NSDirectoryEnumerator* bundlesEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:bundlesPath]
                                  includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsRegularFileKey, NSURLLinkCountKey, NSURLIsSymbolicLinkKey, nil]
                                                     options:0
                                                errorHandler:^(NSURL* url, NSError* error){
                                                    return YES;
                                                }];
    NSMutableSet* bundlesToDelete = [NSMutableSet set];
    for (NSURL *theURL in bundlesEnum) {
        NSNumber *isSymlink;
        if (![theURL getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            continue;
        }
        if ([isSymlink boolValue]) {
            
            NSString* relPath = [[theURL path] substringFromIndex:[bundlesPath length] + 1];
            NSString* bundleDesc = [[relPath pathComponents] objectAtIndex:0];
            NSURL* bundleRes = [NSURL zincResourceForBundleDescriptor:bundleDesc];
            [bundlesToDelete addObject:bundleRes];
        }
    }
    for (NSURL* bundleRes in bundlesToDelete) {
        NSString* path = [self.repo pathForBundleWithId:[bundleRes zincBundleId] version:[bundleRes zincBundleVersion]];
        if (![fm removeItemAtPath:path error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        }
        [self.repo deregisterBundle:bundleRes];
    }
}

- (void) main
{
    [self addEvent:[ZincGarbageCollectionBeginEvent event]];
    [self cleanObjectsDir];
    [self cleanBundlesDir];
    [self addEvent:[ZincGarbageCollectionCompleteEvent event]];
}

@end
