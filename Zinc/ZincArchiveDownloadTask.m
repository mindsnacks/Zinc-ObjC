//
//  ZincArchiveDownloadTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincArchiveDownloadTask.h"
#import "ZincTask+Private.h"
#import "ZincDownloadTask+Private.h"
#import "ZincResource.h"
#import "ZincBundle.h"
#import "ZincRepo+Private.h"
#import "ZincErrors.h"
#import "ZincEvent.h"
#import "ZincSource.h"
#import "ZincHTTPRequestOperation.h"
#import "NSFileManager+Zinc.h"
#import "ZincArchiveExtractOperation.h"
#import "ZincHTTPRequestOperation+ZincContextInfo.h"

@implementation ZincArchiveDownloadTask

- (void)dealloc
{
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

- (void) main
{
    NSString* flavor = self.input;
    
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];

    NSString* catalogId = [ZincBundle catalogIdFromBundleId:self.bundleId];
    NSString* bundleName = [ZincBundle bundleNameFromBundleId:self.bundleId];
    
    NSArray* sources = [self.repo sourcesForCatalogId:catalogId];
    if (sources == nil || [sources count] == 0) {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                              catalogId, @"catalogId", nil];
        error = ZincErrorWithInfo(ZINC_ERR_NO_SOURCES_FOR_CATALOG, info);
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC_METHOD()]];
        return;
    }
    
    NSString* downloadDir = [[self.repo downloadsPath] stringByAppendingPathComponent:catalogId];

    NSString* downloadPath = [downloadDir stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"%@-%d.tar", bundleName, self.version]];
    
    [fm createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:NULL];
    
    for (NSURL* source in sources) {
        
        NSURLRequest* request = [source urlRequestForArchivedBundleName:bundleName version:self.version flavor:flavor];
        NSOutputStream* outStream = [[[NSOutputStream alloc] initToFileAtPath:downloadPath append:NO] autorelease];
        [self queueOperationForRequest:request outputStream:outStream context:self.bundleId];
        
        [self.httpRequestOperation waitUntilFinished];
        if (self.isCancelled) return;
        
        if (!self.httpRequestOperation.hasAcceptableStatusCode) {
            [self addEvent:[ZincErrorEvent eventWithError:self.httpRequestOperation.error source:ZINC_EVENT_SRC_METHOD() attributes:[self.httpRequestOperation zinc_contextInfo]]];
            continue;
        } else {
            [self addEvent:[ZincDownloadCompleteEvent downloadCompleteEventForURL:request.URL size:self.bytesRead]];
        }
        
        [self addEvent:[ZincAchiveExtractBeginEvent archiveExtractBeginEventForResource:self.resource]];
        
        ZincArchiveExtractOperation* extractOp = [[[ZincArchiveExtractOperation alloc] initWithZincRepo:self.repo archivePath:downloadPath] autorelease];
        [self queueChildOperation:extractOp];
        
        [extractOp waitUntilFinished];
        if (self.isCancelled) return;

        if (extractOp.error != nil) {
            [self addEvent:[ZincErrorEvent eventWithError:extractOp.error source:ZINC_EVENT_SRC_METHOD()]];
            continue;
        }
        
        [self addEvent:[ZincAchiveExtractCompleteEvent archiveExtractCompleteEventForResource:self.resource context:self.bundleId]];
        
        self.finishedSuccessfully = YES;
    }
    
    // cleanup
    
    [fm removeItemAtPath:downloadPath error:NULL];
}

@end
