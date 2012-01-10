//
//  ZincFileUpdateTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincFileUpdateTask.h"

#if 0

@implementation ZincFileUpdateTask

- (void) main
{
    NSError* error = nil;
    BOOL gz = NO;
    
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
    
    NSString* path = [self.client pathForFileWithSHA:self.sha];
    NSString* gzpath = [path stringByAppendingPathExtension:@"gz"];
    NSString* dir = [gzpath stringByDeletingLastPathComponent];
    NSString* downloadPath = path;
    if (gz) {
        downloadPath = gzpath;
    }
    
    if (![self.client.fileManager zinc_createDirectoryIfNeededAtPath:dir error:&error]) {
        self.error = error;
        return;
    }
    
    AFHTTPRequestOperation* downloadOp = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    downloadOp.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:200];
    
    //    NSOutputStream* outStream = [[[NSOutputStream alloc] initToFileAtPath:gzpath append:NO] autorelease];
    NSOutputStream* outStream = [[[NSOutputStream alloc] initToFileAtPath:downloadPath append:NO] autorelease];
    downloadOp.outputStream = outStream;
    
    ZINC_DEBUG_LOG(@"[ZincClient 0x%x] Downloading %@", (int)self.client, [request URL]);
    
    [self.client.networkOperationQueue addOperation:downloadOp];    
    [downloadOp waitUntilFinished];
    
    if (!downloadOp.hasAcceptableStatusCode) {
        self.error = downloadOp.error;
        return;
    }
    
    if (gz) {
        NSData* compressed = [[[NSData alloc] initWithContentsOfFile:gzpath] autorelease];
        NSData* uncompressed = [compressed zinc_gzipInflate];
        if (![uncompressed writeToFile:path options:0 error:&error]) {
            self.error = error;
            // don't return! remove the gz file
        }
        [self.client.fileManager removeItemAtPath:gzpath error:NULL];
    }
}


@end

#endif
