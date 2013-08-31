//
//  ZincArchiveDownloadTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincArchiveDownloadTask.h"

#import "ZincInternals.h"
#import "ZincTask+Private.h"
#import "ZincDownloadTask+Private.h"
#import "ZincRepo+Private.h"
#import "ZincHTTPRequestOperation+ZincContextInfo.h"

@implementation ZincArchiveDownloadTask


- (NSString*) bundleID
{
    return [self.resource zincBundleID];
}

- (ZincVersion) version
{
    return [self.resource zincBundleVersion];
}

- (void) main
{
    NSString* flavor = self.input;
    
    NSError* error = nil;
    NSFileManager* fm = [[NSFileManager alloc] init];

    NSString* catalogID = ZincCatalogIDFromBundleID(self.bundleID);
    NSString* bundleName = ZincBundleNameFromBundleID(self.bundleID);
    
    NSArray* sources = [self.repo sourcesForCatalogID:catalogID];
    if (sources == nil || [sources count] == 0) {
        NSDictionary* info = @{@"catalogID": catalogID};
        error = ZincErrorWithInfo(ZINC_ERR_NO_SOURCES_FOR_CATALOG, info);
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
        return;
    }
    
    NSString* downloadDir = [[self.repo downloadsPath] stringByAppendingPathComponent:catalogID];

    NSString* downloadPath = [downloadDir stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"%@-%d.tar", bundleName, self.version]];
    
    [fm createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:NULL];
    
    for (NSURL* source in sources) {
        
        NSURLRequest* request = [source urlRequestForArchivedBundleName:bundleName version:self.version flavor:flavor];
        NSOutputStream* outStream = [[NSOutputStream alloc] initToFileAtPath:downloadPath append:NO];
        [self queueOperationForRequest:request outputStream:outStream context:self.bundleID];
        
        [self.httpRequestOperation waitUntilFinished];
        if (self.isCancelled) return;
        
        if (!self.httpRequestOperation.hasAcceptableStatusCode) {
            [self addEvent:[ZincErrorEvent eventWithError:self.httpRequestOperation.error source:ZINC_EVENT_SRC() attributes:[self.httpRequestOperation zinc_contextInfo]]];
            continue;
        } else {
            [self addEvent:[ZincDownloadCompleteEvent downloadCompleteEventForURL:request.URL size:self.bytesRead]];
        }
        
        [self addEvent:[ZincArchiveExtractBeginEvent archiveExtractBeginEventForResource:self.resource]];
        
        ZincArchiveExtractOperation* extractOp = [[ZincArchiveExtractOperation alloc] initWithZincRepo:self.repo archivePath:downloadPath];
        [self queueChildOperation:extractOp];
        
        [extractOp waitUntilFinished];
        if (self.isCancelled) return;

        if (extractOp.error != nil) {
            [self addEvent:[ZincErrorEvent eventWithError:extractOp.error source:ZINC_EVENT_SRC()]];
            continue;
        }
        
        [self addEvent:[ZincArchiveExtractCompleteEvent archiveExtractCompleteEventForResource:self.resource context:self.bundleID]];
        
        self.finishedSuccessfully = YES;
    }
    
    // cleanup
    
    [fm removeItemAtPath:downloadPath error:NULL];
}

@end
