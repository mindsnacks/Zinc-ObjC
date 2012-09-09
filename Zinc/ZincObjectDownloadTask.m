//
//  ZincFileUpdateTask2.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincObjectDownloadTask.h"
#import "ZincTask+Private.h"
#import "ZincDownloadTask+Private.h"
#import "ZincSource.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincEvent.h"
#import "ZincResource.h"
#import "NSFileManager+Zinc.h"
#import "NSData+Zinc.h"
#import "ZincErrors.h"
#import "ZincUtils.h"
#import "ZincHTTPRequestOperation.h"

@interface ZincObjectDownloadTask ()
@property (readwrite) NSInteger bytesRead;
@property (readwrite) NSInteger totalBytesToRead;
@end


@implementation ZincObjectDownloadTask

@synthesize bytesRead = _bytesRead;
@synthesize totalBytesToRead = _totalBytesToRead;

- (void)dealloc
{
    [super dealloc];
}

- (NSString*) sha
{
    return [self.resource zincObjectSHA];
}

- (void) main
{
    NSError* error = nil;
    BOOL gz = NO;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    
    NSArray* formats = (NSArray*)[self input];
    
    if ([formats containsObject:ZincFileFormatGZ]) {
        gz = YES;
    }
        
    NSString* ext = nil;
    if (gz) {
        ext = @"gz";
    }
    
    NSString* catalogId = [self.resource zincCatalogId];
    
    NSArray* sources = [self.repo sourcesForCatalogId:catalogId];
    if (sources == nil || [sources count] == 0) {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                              catalogId, @"catalogId", nil];
        error = ZincErrorWithInfo(ZINC_ERR_NO_SOURCES_FOR_CATALOG, info);
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    for (NSURL* source in sources) {
        
        NSString* uncompressedPath = [[self.repo downloadsPath] stringByAppendingPathComponent:self.sha];
        NSString* compressedPath = [uncompressedPath stringByAppendingPathExtension:@"gz"];
        
        if ([fm fileExistsAtPath:uncompressedPath]) {
            if (![fm removeItemAtPath:uncompressedPath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                continue;
            }
        }
        
        if ([fm fileExistsAtPath:compressedPath]) {
            if (![fm removeItemAtPath:compressedPath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                continue;
            }
        }
        
        NSString* downloadPath = uncompressedPath;
        if (gz) {
            downloadPath = compressedPath;
        }
        
        NSURLRequest* request = [source urlRequestForFileWithSHA:self.sha extension:ext];
        NSOutputStream* outStream = [[[NSOutputStream alloc] initToFileAtPath:downloadPath append:NO] autorelease];
        ZincHTTPRequestOperation* downloadOp  = [self queuedOperationForRequest:request outputStream:outStream context:nil];
        
        [downloadOp waitUntilFinished];
        if (self.isCancelled) return;
        
        if (!downloadOp.hasAcceptableStatusCode) {
            [self addEvent:[ZincErrorEvent eventWithError:downloadOp.error source:self]];
            continue;
        } else {
            [self addEvent:[ZincDownloadCompleteEvent downloadCompleteEventForURL:request.URL]];
        }
        
        NSString* targetPath = [self.repo pathForFileWithSHA:self.sha];
        
        if (gz) {
            NSData* compressed = [[[NSData alloc] initWithContentsOfFile:downloadPath] autorelease];
            NSData* uncompressed = [compressed zinc_gzipInflate];
            if (![uncompressed writeToFile:uncompressedPath options:0 error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                // don't return/continue! still need to clean up
            }
        } 
        
        NSString* actualSha = [fm zinc_sha1ForPath:uncompressedPath];
        if (![actualSha isEqualToString:self.sha]) {
            
            NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    self.sha, @"expectedSHA",
                    actualSha, @"actualSHA",
                    source, @"source",
                    nil];
            error = ZincErrorWithInfo(ZINC_ERR_SHA_MISMATCH, info);
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            continue;
            
        } else {
            
            NSString* targetDir = [targetPath stringByDeletingLastPathComponent];
            if (![fm zinc_createDirectoryIfNeededAtPath:targetDir error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                continue;
            }
            
            if (![fm moveItemAtPath:uncompressedPath toPath:targetPath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                continue;
            }
            
            ZincAddSkipBackupAttributeToFileWithPath(targetPath);
            self.finishedSuccessfully = YES;
        }
        
        if (compressedPath != nil) {
            [fm removeItemAtPath:compressedPath error:NULL];
        }
        
        if (uncompressedPath != nil) {
            [fm removeItemAtPath:uncompressedPath error:NULL];
        }
        
        self.finishedSuccessfully = YES;
        
        break; // make sure to break out of the loop when we finish successfully 
    }
}


@end
