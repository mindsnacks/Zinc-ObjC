//
//  ZincArchiveDownloadTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincArchiveDownloadTask.h"
#import "ZincResource.h"
#import "ZincBundle.h"
#import "ZincRepo+Private.h"
#import "ZincErrors.h"
#import "ZincEvent.h"
#import "ZincSource.h"
#import "AFHTTPRequestOperation.h"
#import "NSFileManager+Zinc.h"
#import "ZincArchiveExtractOperation.h"

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
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];

    NSString* catalogId = [ZincBundle catalogIdFromBundleId:self.bundleId];
    NSString* bundleName = [ZincBundle bundleNameFromBundleId:self.bundleId];
    
    NSArray* sources = [self.repo sourcesForCatalogId:catalogId];
    if (sources == nil || [sources count] == 0) {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                              catalogId, @"catalogId", nil];
        error = ZincErrorWithInfo(ZINC_ERR_NO_SOURCES_FOR_CATALOG, info);
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    NSString* downloadDir = [[self.repo downloadsPath] stringByAppendingPathComponent:catalogId];

    
    NSString* downloadPath = [downloadDir stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"%@-%d.tar", bundleName, self.version]];
    
    for (NSURL* source in sources) {
        
        NSURLRequest* request = [source urlRequestForArchivedBundleName:bundleName version:self.version];
        
        AFHTTPRequestOperation* downloadOp = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
        downloadOp.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:200];
        
        NSOutputStream* outStream = [[[NSOutputStream alloc] initToFileAtPath:downloadPath append:NO] autorelease];
        downloadOp.outputStream = outStream;
        
        [self addEvent:[ZincDownloadBeginEvent downloadBeginEventForURL:request.URL]];
        
        [self addOperation:downloadOp];
        [downloadOp waitUntilFinished];
        
        if (!downloadOp.hasAcceptableStatusCode) {
            [self addEvent:[ZincErrorEvent eventWithError:downloadOp.error source:self]];
            continue;
        } else {
            [self addEvent:[ZincDownloadCompleteEvent downloadCompleteEventForURL:request.URL]];
        }
        
        [self addEvent:[ZincAchiveExtractBeginEvent archiveExtractBeginEventForResource:self.resource]];
        
        ZincArchiveExtractOperation* extractOp = [[[ZincArchiveExtractOperation alloc] initWithZincRepo:self.repo archivePath:downloadPath] autorelease];
        [self addOperation:extractOp];
        [extractOp waitUntilFinished];
        
        if (extractOp.error != nil) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            continue;
        }
        
        [self addEvent:[ZincAchiveExtractCompleteEvent archiveExtractCompleteEventForResource:self.resource]];
        
        self.finishedSuccessfully = YES;
    }
    
    // cleanup
    
    [fm removeItemAtPath:downloadPath error:NULL];
}

@end
