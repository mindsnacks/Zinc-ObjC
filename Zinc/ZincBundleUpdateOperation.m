//
//  ZincBundleUpdateOperation.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleUpdateOperation.h"
#import "ZincClient+Private.h"
#import "ZincManifest.h"
#import "ZincManifestUpdateOperation.h"
#import "ZincEvent.h"
#import "NSFileManager+Zinc.h"
#import "ZincFileUpdateTask2.h"

@implementation ZincBundleUpdateOperation

@synthesize bundleId = _bundleId;
@synthesize version = _version;

- (id)initWithClient:(ZincClient *)client bundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
{
    self = [super initWithClient:client];
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
    
//    NSString* manifestUpdateName = [ZincManifestUpdateOperation nameForBundleId:self.bundleId version:self.version];
//    ZincOperation* manifestOp = [self.client getOperationWithDescriptor:manifestUpdateName];
//    if (manifestOp == nil) {
//        if (![self.client hasManifestForBundleIdentifier:self.bundleId version:self.version]) {
//            manifestOp = [[[ZincManifestUpdateOperation alloc] initWithClient:self.client bundleIdentifier:self.bundleId version:self.version] autorelease];
//            //manifestOp = (ZincOperation*)[self.client addOperationToPrimaryQueue:manifestOp];
//            [self.client addOperation:manifestOp];
//        }
//    }
    
    // TODO: fix this mess
    
    ZincManifestUpdateOperation* manifestOp = [[[ZincManifestUpdateOperation alloc] initWithClient:self.client bundleIdentifier:self.bundleId version:self.version] autorelease];
    
    if ([self.client taskForKey:[manifestOp key]] ||
        (![self.client hasManifestForBundleIdentifier:self.bundleId version:self.version])) {
        manifestOp = (ZincManifestUpdateOperation*)[self.client getOrAddTask:manifestOp];

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
    
    ZincManifest* manifest = [self.client manifestWithBundleIdentifier:self.bundleId version:self.version error:&error];
    if (manifest == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    NSString* catalogId = [ZincBundle sourceFromBundleIdentifier:self.bundleId];
    NSArray* sources = [self.client sourcesForCatalogIdentifier:catalogId];
    if (sources == nil || [sources count] == 0) {
        // TODO: error, log, or requeue or SOMETHING
        return;
    }
    
    NSArray* SHAs = [manifest allSHAs];
    NSMutableArray* fileOps = [NSMutableArray arrayWithCapacity:[SHAs count]];
    
    for (NSString* expectedSHA in SHAs) {
        NSString* path = [self.client pathForFileWithSHA:expectedSHA];
        NSString* actualSHA = [fm zinc_sha1ForPath:path];
        
        // check if file is missing or invalid
        if (actualSHA == nil || ![expectedSHA isEqualToString:actualSHA]) {
            
            // queue redownload
            ZincSource* source = [sources lastObject]; // TODO: fix lastobject
            NSAssert(source, @"source is nil");
            ZincTask2* fileOp = 
            [[[ZincFileUpdateTask2 alloc] initWithClient:self.client
                                                          source:source
                                                             sha:expectedSHA] autorelease];
            //            op = [self.client addOperationToPrimaryQueue:op];
            fileOp = [self.client getOrAddTask:fileOp];
            [fileOps addObject:fileOp];
        }
    }
    
    BOOL allSuccessful = YES;
    
    for (ZincTask2* op in fileOps) {
        [op waitUntilFinished];
        if (!op.finishedSuccessfully) {
            allSuccessful = NO;
        }
    }
    
    if (!allSuccessful) return;
    
    NSString* bundlePath = [self.client pathForBundleWithId:self.bundleId version:self.version];
    NSArray* allFiles = [manifest allFiles];
    for (NSString* file in allFiles) {
        NSString* filePath = [bundlePath stringByAppendingPathComponent:file];
        NSString* fileDir = [filePath stringByDeletingLastPathComponent];
        if (![fm zinc_createDirectoryIfNeededAtPath:fileDir error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            return;
        }
        
        NSString* shaPath = [self.client pathForFileWithSHA:[manifest shaForFile:file]];
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





#if 0
- (void) main
{
    //ZINC_DEBUG_LOG(@"ENSURING BUNDLE %@!", self.bundleId);
    
    NSError* error = nil;
    
//    NSString* manifestUpdateName = [ZincManifestUpdateOperation nameForBundleId:self.bundleId version:self.version];
//    ZincOperation* manifestOp = [self.client getOperationWithDescriptor:manifestUpdateName];
//    if (manifestOp == nil) {
//        if (![self.client hasManifestForBundleIdentifier:self.bundleId version:self.version]) {
//            manifestOp = [[[ZincManifestUpdateOperation alloc] initWithClient:self.client bundleIdentifier:self.bundleId version:self.version] autorelease];
//            //manifestOp = (ZincOperation*)[self.client addOperationToPrimaryQueue:manifestOp];
//            [self.client addOperation:manifestOp];
//        }
//    }
//    
//    if (manifestOp != nil) {
//        [manifestOp waitUntilFinished];
//        if (manifestOp.error != nil) {
//            self.error = manifestOp.error;
//            return;
//        }
//    }
    
    ZincManifestUpdateTask* manifestTask = [[[ZincManifestUpdateTask alloc] initWithClient:self.client bundleId:nil version:0] autotrelease];
    manifestTask = [self addSubtask:manifestTask];
    
    
    ZincManifest* manifest = [self.client manifestWithBundleIdentifier:self.bundleId version:self.version error:&error];
    if (manifest == nil) {
        self.error = error;
        return;
    }
    
    NSString* catalogId = [ZincBundle sourceFromBundleIdentifier:self.bundleId];
    NSArray* sources = [self.client sourcesForCatalogIdentifier:catalogId];
    if (sources == nil || [sources count] == 0) {
        // TODO: error, log, or requeue or SOMETHING
        return;
    }
    
    NSArray* SHAs = [manifest allSHAs];
    NSMutableArray* fileOps = [NSMutableArray arrayWithCapacity:[SHAs count]];
    
    for (NSString* expectedSHA in SHAs) {
        NSString* path = [self.client pathForFileWithSHA:expectedSHA];
        NSString* actualSHA = [self.client.fileManager zinc_sha1ForPath:path];
        
        // check if file is missing or invalid
        if (actualSHA == nil || ![expectedSHA isEqualToString:actualSHA]) {
            
            // queue redownload
            ZincSource* source = [sources lastObject]; // TODO: fix lastobject
            NSAssert(source, @"source is nil");
            ZincOperation* fileOp = 
            [[[ZincRepoFileUpdateOperation alloc] initWithClient:self.client
                                                          source:source
                                                             sha:expectedSHA] autorelease];
            //            op = [self.client addOperationToPrimaryQueue:op];
            [self.client addOperation:fileOp];
            [fileOps addObject:fileOp];
        }
    }
    
    NSMutableArray* errors = [NSMutableArray array];
    for (ZincOperation* op in fileOps) {
        [op waitUntilFinished];
        if (op.error != nil) {
            [errors addObject:op.error];
        }
    }
    
    NSString* bundlePath = [self.client pathForBundleWithId:self.bundleId version:self.version];
    NSArray* allFiles = [manifest allFiles];
    for (NSString* file in allFiles) {
        NSString* filePath = [bundlePath stringByAppendingPathComponent:file];
        NSString* fileDir = [filePath stringByDeletingLastPathComponent];
        if (![self.client.fileManager zinc_createDirectoryIfNeededAtPath:fileDir error:&error]) {
            self.error = error;
            return;
        }
        
        NSString* shaPath = [self.client pathForFileWithSHA:[manifest shaForFile:file]];
        BOOL createLink = NO;
        if ([self.client.fileManager fileExistsAtPath:filePath]) {
            NSString* dst = [self.client.fileManager destinationOfSymbolicLinkAtPath:filePath error:NULL];
            if (![dst isEqualToString:shaPath]) {
                if (![self.client.fileManager removeItemAtPath:filePath error:&error]) {
                    self.error = error;
                    return;
                }
                createLink = YES;
            }
        } else {
            createLink = YES;
        }
        
        if (createLink) {
            if (![self.client.fileManager createSymbolicLinkAtPath:filePath withDestinationPath:shaPath error:&error]) {
                self.error = error;
                return;
            }
        }
    }
    
    if ([errors count] == 0) {
        
        ZINC_DEBUG_LOG(@"FINISHED BUNDLE %@!", self.bundleId);
    }
}
#endif



@end
