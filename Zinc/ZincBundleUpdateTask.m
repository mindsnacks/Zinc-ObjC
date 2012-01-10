//
//  ZincBundleUpdateOperation.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleUpdateTask.h"
#import "ZincRepo+Private.h"
#import "ZincManifest.h"
#import "ZincManifestUpdateTask.h"
#import "ZincEvent.h"
#import "NSFileManager+Zinc.h"
#import "ZincFileUpdateTask.h"

@implementation ZincBundleUpdateTask

@synthesize bundleId = _bundleId;
@synthesize version = _version;

- (id)initWithRepo:(ZincRepo *)repo bundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
{
    self = [super initWithRepo:repo];
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

- (NSString*) key
{
    return [NSString stringWithFormat:@"%@:%@-$d",
            NSStringFromClass([self class]),
            self.bundleId, self.version];
}

- (void) main
{
    ZINC_DEBUG_LOG(@"ENSURING BUNDLE %@!", self.bundleId);
    
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    
    // TODO: fix this mess
    
    ZincManifestUpdateTask* manifestOp = [[[ZincManifestUpdateTask alloc] initWithRepo:self.self.repo bundleIdentifier:self.bundleId version:self.version] autorelease];
    
    if ([self.self.repo taskForKey:[manifestOp key]] ||
        (![self.self.repo hasManifestForBundleIdentifier:self.bundleId version:self.version])) {
        manifestOp = (ZincManifestUpdateTask*)[self.self.repo getOrAddTask:manifestOp];

    } else {
        // no update required
        manifestOp = nil;
    }
    
    if (manifestOp != nil) {
        [manifestOp waitUntilFinished];
        if (!manifestOp.finishedSuccessfully) {
            // TODO: add events?
            return;
        }
    }
    
    ZincManifest* manifest = [self.self.repo manifestWithBundleIdentifier:self.bundleId version:self.version error:&error];
    if (manifest == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    NSString* catalogId = [ZincBundle sourceFromBundleIdentifier:self.bundleId];
    NSArray* sources = [self.self.repo sourcesForCatalogIdentifier:catalogId];
    if (sources == nil || [sources count] == 0) {
        // TODO: error, log, or requeue or SOMETHING
        return;
    }
    
    NSArray* SHAs = [manifest allSHAs];
    NSMutableArray* fileOps = [NSMutableArray arrayWithCapacity:[SHAs count]];
    
    for (NSString* expectedSHA in SHAs) {
        NSString* path = [self.self.repo pathForFileWithSHA:expectedSHA];
        NSString* actualSHA = [fm zinc_sha1ForPath:path];
        
        // check if file is missing or invalid
        if (actualSHA == nil || ![expectedSHA isEqualToString:actualSHA]) {
            
            // queue redownload
            ZincSource* source = [sources lastObject]; // TODO: fix lastobject
            NSAssert(source, @"source is nil");
            ZincTask* fileOp = 
            [[[ZincFileUpdateTask alloc] initWithRepo:self.self.repo
                                                          source:source
                                                             sha:expectedSHA] autorelease];
            fileOp = [self.self.repo getOrAddTask:fileOp];
            [fileOps addObject:fileOp];
        }
    }
    
    BOOL allSuccessful = YES;
    
    for (ZincTask* op in fileOps) {
        [op waitUntilFinished];
        if (!op.finishedSuccessfully) {
            allSuccessful = NO;
        }
    }
    
    if (!allSuccessful) return;
    
    NSString* bundlePath = [self.self.repo pathForBundleWithId:self.bundleId version:self.version];
    NSArray* allFiles = [manifest allFiles];
    for (NSString* file in allFiles) {
        NSString* filePath = [bundlePath stringByAppendingPathComponent:file];
        NSString* fileDir = [filePath stringByDeletingLastPathComponent];
        if (![fm zinc_createDirectoryIfNeededAtPath:fileDir error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            return;
        }
        
        NSString* shaPath = [self.self.repo pathForFileWithSHA:[manifest shaForFile:file]];
        BOOL createLink = NO;
        if ([fm fileExistsAtPath:filePath]) {
            NSString* dst = [fm destinationOfSymbolicLinkAtPath:filePath error:NULL];
            if (![dst isEqualToString:shaPath]) {
                if (![fm removeItemAtPath:filePath error:&error]) {
                    [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                    return;
                }
                createLink = YES;
            }
        } else {
            createLink = YES;
        }
        
        if (createLink) {
            if (![fm createSymbolicLinkAtPath:filePath withDestinationPath:shaPath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                return;
            }
        }
    }
    
    ZINC_DEBUG_LOG(@"FINISHED BUNDLE %@!", self.bundleId);
    
    self.finishedSuccessfully = YES;
}

@end
