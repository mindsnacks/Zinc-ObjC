//
//  ZincCleanLegacySymlinksTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/18/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincCleanLegacySymlinksTask.h"
#import "ZincTask+Private.h"
#import "ZincRepo+Private.h"
#import "ZincEvent.h"
#import "ZincResource.h"

@implementation ZincCleanLegacySymlinksTask

+ (NSString *)action
{
    return @"CleanLegacySymlinks";
}

- (void) cleanObjectsDir
{
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    NSDirectoryEnumerator* filesEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:[self.repo filesPath]]
                                includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsSymbolicLinkKey, nil]
                                                   options:0
                                              errorHandler:^(NSURL* url, NSError* error){
                                                  return YES;
                                              }];
    for (NSURL *theURL in filesEnum) {
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

- (void) cleanBundlesDir
{
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
            NSUInteger endIndexOfBundleDir = NSMaxRange([[theURL path] rangeOfString:bundlesPath]);
            NSString* relPath = [[theURL path] substringFromIndex:endIndexOfBundleDir + 1];
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

- (void) doMaintenance
{
    [self cleanObjectsDir];
    [self cleanBundlesDir];
}

@end
