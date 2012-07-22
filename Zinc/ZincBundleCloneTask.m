//
//  ZincBundleCloneTask.m
//  
//
//  Created by Andy Mroczkowski on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZincBundleCloneTask.h"
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

- (void) setUp
{
    self.fileManager = [[[NSFileManager alloc] init] autorelease];
    [self addEvent:[ZincBundleCloneBeginEvent bundleCloneBeginEventForBundleResource:self.resource source:self]];
}

- (void) complete
{
    [self.repo registerBundle:self.resource status:ZincBundleStateAvailable];
    [self addEvent:[ZincBundleCloneCompleteEvent bundleCloneCompleteEventForBundleResource:self.resource source:self context:self.bundleId]];
    self.finishedSuccessfully = YES;
}

- (BOOL) createBundleLinksForManifest:(ZincManifest*)manifest
{
    NSError* error = nil;
    
    NSArray* allFiles = [manifest allFiles];
    NSString* bundlePath = [self.repo pathForBundleWithId:self.bundleId version:self.version];
    for (NSString* file in allFiles) {
        NSString* filePath = [bundlePath stringByAppendingPathComponent:file];
        NSString* fileDir = [filePath stringByDeletingLastPathComponent];
        if (![self.fileManager zinc_createDirectoryIfNeededAtPath:fileDir error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            return NO;
        }
        
        NSString* shaPath = [self.repo pathForFileWithSHA:[manifest shaForFile:file]];
        BOOL createLink = NO;
        if ([self.fileManager fileExistsAtPath:filePath]) {
            NSString* dst = [self.fileManager destinationOfSymbolicLinkAtPath:filePath error:NULL];
            if (![dst isEqualToString:shaPath]) {
                if (![self.fileManager removeItemAtPath:filePath error:&error]) {
                    [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                    return NO;
                }
                createLink = YES;
            }
        } else {
            createLink = YES;
        }
        
        if (createLink) {
            if (![self.fileManager linkItemAtPath:shaPath toPath:filePath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                return NO;
            }
        }
    }
    return YES;
}

@end
