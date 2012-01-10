//
//  ZincFileUpdateTask2.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincFileUpdateTask.h"
#import "Zinc.h"
#import "ZincSource.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "AFHTTPRequestOperation.h"
#import "ZincEvent.h"
#import "NSFileManager+Zinc.h"
#import "NSData+Zinc.h"

@implementation ZincFileUpdateTask

@synthesize source = _source;
@synthesize sha = _sha;

- (id)initWithRepo:(ZincRepo*)repo source:(ZincSource*)souce sha:(NSString*)sha
{
    self = [super initWithRepo:repo];
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

- (NSString*) key
{
    return [NSString stringWithFormat:@"%@:%@",
            NSStringFromClass([self class]),
            self.sha];
}

- (void) main
{
    NSError* error = nil;
    BOOL gz = NO;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    
    NSString* ext = nil;
    if (gz) {
        ext = @"gz";
    }
    
    //NSURLRequest* request = [self.source urlRequestForFileWithSHA:self.sha];
    NSURLRequest* request = [self.source urlRequestForFileWithSHA:self.sha extension:ext];
    if (request == nil) {
        // TODO: better error
        NSAssert(0, @"request is nil");
        return;
    }
    
    NSString* path = [self.self.repo pathForFileWithSHA:self.sha];
    NSString* gzpath = [path stringByAppendingPathExtension:@"gz"];
    NSString* dir = [gzpath stringByDeletingLastPathComponent];
    NSString* downloadPath = path;
    if (gz) {
        downloadPath = gzpath;
    }
    
    if (![fm zinc_createDirectoryIfNeededAtPath:dir error:&error]) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    AFHTTPRequestOperation* downloadOp = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    downloadOp.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:200];
    
    //    NSOutputStream* outStream = [[[NSOutputStream alloc] initToFileAtPath:gzpath append:NO] autorelease];
    NSOutputStream* outStream = [[[NSOutputStream alloc] initToFileAtPath:downloadPath append:NO] autorelease];
    downloadOp.outputStream = outStream;
    
    ZINC_DEBUG_LOG(@"[Zincself.repo 0x%x] Downloading %@", (int)self.self.repo, [request URL]);

    [self.self.repo addOperation:downloadOp];
    [downloadOp waitUntilFinished];
    
    if (!downloadOp.hasAcceptableStatusCode) {
        [self addEvent:[ZincErrorEvent eventWithError:downloadOp.error source:self]];
        return;
    }
    
    if (gz) {
        NSData* compressed = [[[NSData alloc] initWithContentsOfFile:gzpath] autorelease];
        NSData* uncompressed = [compressed zinc_gzipInflate];
        if (![uncompressed writeToFile:path options:0 error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            // don't return! remove the gz file
        } else {
            self.finishedSuccessfully = YES;
        }
        
        [fm removeItemAtPath:gzpath error:NULL];
        
    } else {
        self.finishedSuccessfully = YES;
    }
}


@end
