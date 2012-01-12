//
//  ZincFileUpdateTask2.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincFileDownloadTask.h"
#import "Zinc.h"
#import "ZincSource.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincEvent.h"
#import "ZincResourceDescriptor.h"
#import "NSFileManager+Zinc.h"
#import "NSData+Zinc.h"
#import "AFHTTPRequestOperation.h"

@implementation ZincFileDownloadTask

@synthesize source = _source;
@synthesize sha = _sha;

- (id)initWithRepo:(ZincRepo*)repo source:(ZincSource*)souce sha:(NSString*)sha
{
    ZincFileDescriptor* fd = [[[ZincFileDescriptor alloc] init] autorelease];
    fd.sha = sha;
    
    self = [super initWithRepo:repo resourceDescriptor:fd];
    if (self) {
        self.source = souce;
        self.sha = sha;
    }
    return self;
}

- (void)dealloc
{
    self.source = nil;
    self.sha = nil;
    [super dealloc];
}

- (void) main
{
    NSError* error = nil;
    BOOL gz = YES;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    
    NSString* ext = nil;
    if (gz) {
        ext = @"gz";
    }
    
    NSURLRequest* request = [self.source urlRequestForFileWithSHA:self.sha extension:ext];
    if (request == nil) {
        // TODO: better error
        NSAssert(0, @"request is nil");
        return;
    }
    
    NSString* uncompressedPath = [ZincGetApplicationCacheDirectory() stringByAppendingPathComponent:self.sha];
    NSString* compressedPath = [uncompressedPath stringByAppendingPathExtension:@"gz"];

    if ([fm fileExistsAtPath:uncompressedPath]) {
        if (![fm removeItemAtPath:uncompressedPath error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            return;
        }
    }
    
    if ([fm fileExistsAtPath:compressedPath]) {
        if (![fm removeItemAtPath:compressedPath error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            return;
        }
    }

    NSString* downloadPath = uncompressedPath;
    if (gz) {
        downloadPath = compressedPath;
    }
    
    AFHTTPRequestOperation* downloadOp = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    downloadOp.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:200];
    
    NSOutputStream* outStream = [[[NSOutputStream alloc] initToFileAtPath:downloadPath append:NO] autorelease];
    downloadOp.outputStream = outStream;
    
    ZINC_DEBUG_LOG(@"[ZincRepo 0x%x] Downloading %@", (int)self.repo, [request URL]);

    [self addOperation:downloadOp];
    [downloadOp waitUntilFinished];
    
    if (!downloadOp.hasAcceptableStatusCode) {
        [self addEvent:[ZincErrorEvent eventWithError:downloadOp.error source:self]];
        return;
    }
    
    NSString* targetPath = [self.repo pathForFileWithSHA:self.sha];

    if (gz) {
        NSData* compressed = [[[NSData alloc] initWithContentsOfFile:downloadPath] autorelease];
        NSData* uncompressed = [compressed zinc_gzipInflate];
        if (![uncompressed writeToFile:uncompressedPath options:0 error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            // don't return! still need to clean up
        } else {
        }
    } 
    
    NSString* sourceSha = [fm zinc_sha1ForPath:uncompressedPath];
    if (![sourceSha isEqualToString:self.sha]) {
        
        // LOG SOME BAD EVENT!
        
    } else {
        
        NSString* targetDir = [targetPath stringByDeletingLastPathComponent];
        if (![fm zinc_createDirectoryIfNeededAtPath:targetDir error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            return;
        }
        
        if (![fm moveItemAtPath:uncompressedPath toPath:targetPath error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            return;
        }
        
        ZincAddSkipBackupAttributeToFile([NSURL fileURLWithPath:targetPath]);
        self.finishedSuccessfully = YES;
    }

    if (compressedPath != nil) {
        [fm removeItemAtPath:compressedPath error:NULL];
    }
    
    if (uncompressedPath != nil) {
        [fm removeItemAtPath:uncompressedPath error:NULL];
    }
}


@end
