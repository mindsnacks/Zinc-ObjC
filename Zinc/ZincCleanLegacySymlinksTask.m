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

@interface ZincCleanLegacySymlinksTask ()
@property (assign) long long totalItemsToClean;
@property (assign) long long itemsCleaned;
@end

@implementation ZincCleanLegacySymlinksTask

+ (NSString *)action
{
    return @"CleanLegacySymlinks";
}

- (long long) currentProgressValue
{
    return self.itemsCleaned;
}

- (long long) maxProgressValue
{
    return self.totalItemsToClean;
}

- (void) doMaintenance
{
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    
    // -- Create both enumerators
    
    NSDirectoryEnumerator* filesEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:[self.repo filesPath]]
                                includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsSymbolicLinkKey, nil]
                                                   options:0
                                              errorHandler:^(NSURL* url, NSError* error){
                                                  return YES;
                                              }];
    
    NSString* bundlesPath = [self.repo bundlesPath];
    NSDirectoryEnumerator* bundlesEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:bundlesPath]
                                  includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsSymbolicLinkKey, nil]
                                                     options:0
                                                errorHandler:^(NSURL* url, NSError* error){
                                                    return YES;
                                                }];
    
    
    // -- Calculate Total Progress
    
    NSArray* allFileURLs = [filesEnum allObjects];
    NSArray* allBundleURLs = [bundlesEnum allObjects];
    
    self.totalItemsToClean = [allFileURLs count] + [allBundleURLs count];
    
    // -- Clean Files
    
    for (NSURL *theURL in allFileURLs) {
        
        NSNumber *isSymlink;
        if (![theURL getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            continue;
        }
        if ([isSymlink boolValue]) {
            [fm removeItemAtURL:theURL error:NULL];
        }
        
        self.itemsCleaned++;
    }
    
    // -- Clean Bundles

    NSMutableSet* bundlesToDelete = [NSMutableSet set];
    for (NSURL *theURL in allBundleURLs) {
        
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

            // If we find a entire bundle to delete, increment the total work count.
            // We will increment itemsCleaned in the loop over bundlesToDelete
            self.totalItemsToClean++;
        }
        
        self.itemsCleaned++;
    }
    for (NSURL* bundleRes in bundlesToDelete) {
        NSString* path = [self.repo pathForBundleWithId:[bundleRes zincBundleId] version:[bundleRes zincBundleVersion]];
        if (![fm removeItemAtPath:path error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        }
        [self.repo deregisterBundle:bundleRes];
        
        self.itemsCleaned++;
    }
}

@end
