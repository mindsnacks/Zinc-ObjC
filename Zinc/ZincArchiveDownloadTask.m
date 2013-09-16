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

@interface ZincArchiveDownloadTask ()
@property (nonatomic, strong) ZincArchiveExtractOperation* extractOp;
@property (nonatomic, strong) NSString* downloadPath;
@end


@implementation ZincArchiveDownloadTask

- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input
{
    self = [super initWithRepo:repo resourceDescriptor:resource input:input];
    if (self) {

        NSString* catalogID = ZincCatalogIDFromBundleID(self.bundleID);
        NSString* bundleName = ZincBundleNameFromBundleID(self.bundleID);
        
        NSString* downloadDir = [[self.repo downloadsPath] stringByAppendingPathComponent:catalogID];
        self.downloadPath = [downloadDir stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"%@-%ld.tar", bundleName, (long)self.version]];


        ZincManifest* manifest = [repo manifestWithBundleID:[resource zincBundleID] version:[resource zincBundleVersion] error:NULL];

        self.extractOp = [[ZincArchiveExtractOperation alloc] initWithZincRepo:self.repo archivePath:self.downloadPath manifest:manifest];
        [self addChildOperation:self.extractOp];
    }
    return self;
}

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

    [fm createDirectoryAtPath:[self.downloadPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    
    for (NSURL* source in sources) {
        
        NSURLRequest* request = [source urlRequestForArchivedBundleName:bundleName version:self.version flavor:flavor];
        NSOutputStream* outStream = [[NSOutputStream alloc] initToFileAtPath:self.downloadPath append:NO];
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
        
        [self queueChildOperation:self.extractOp];
        
        [self.extractOp waitUntilFinished];
        if (self.isCancelled) return;

        if (self.extractOp.error != nil) {
            [self addEvent:[ZincErrorEvent eventWithError:self.extractOp.error source:ZINC_EVENT_SRC()]];
            continue;
        }
        
        [self addEvent:[ZincArchiveExtractCompleteEvent archiveExtractCompleteEventForResource:self.resource context:self.bundleID]];
        
        self.finishedSuccessfully = YES;
    }
    
    // cleanup
    
    [fm removeItemAtPath:self.downloadPath error:NULL];
}

@end
