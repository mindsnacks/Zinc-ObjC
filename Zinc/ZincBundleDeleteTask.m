//
//  ZincBundleDeleteTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleDeleteTask.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincEvent.h"
#import "ZincManifest.h"
#import "ZincResource.h"

@implementation ZincBundleDeleteTask

@synthesize bundleId = _bundleId;
@synthesize version = _version;

- (id)initWithRepo:(ZincRepo *)repo bundleId:(NSString*)bundleId version:(ZincVersion)version;
{
    NSURL* res = [NSURL zincResourceForBundleWithId:bundleId version:version];
    self = [super initWithRepo:repo resourceDescriptor:res];
    if (self) {
        self.bundleId = bundleId;
        self.version = version;
    }
    return self;
}

- (void)dealloc
{
    self.bundleId = nil;
    [super dealloc];
}

- (void) main
{
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];

    ZincManifest* manifest = [self.repo manifestWithBundleIdentifier:self.bundleId version:self.version error:&error];
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
    
    NSDirectoryEnumerator* dirEnum = [fm enumeratorAtPath:bundlePath];
    
    // first pass, scan to find any shared sha-based files to delete
    for (NSString *thePath in dirEnum) {
        
        NSString* fullPath = [bundlePath stringByAppendingPathComponent:thePath];
        
        NSDictionary* attr = [fm attributesOfItemAtPath:fullPath error:&error];
        if (attr == nil) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            continue;
        }
        
        if ([[attr objectForKey:NSFileType] isEqualToString:NSFileTypeRegular]) {
            
            NSNumber* linkCount = [attr objectForKey:NSFileReferenceCount];
            
            // check the link count. if it's 2, it means the only links are the
            // one in this bundle, and the original in files/<sha>
            if ([linkCount integerValue] == 2) {
                
                NSString* sha = [manifest shaForFile:thePath];
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
    
    // remove the bundle dir    
    if (![fm removeItemAtPath:bundlePath error:&error]) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    // finally remove the manifest
    if(![self.repo removeManifestForBundleId:self.bundleId version:self.version error:&error]) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }

    self.finishedSuccessfully = YES;
}

@end
