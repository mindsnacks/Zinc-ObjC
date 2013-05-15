//
//  ZincManifestUpdateOperation.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincManifestDownloadTask.h"
#import "ZincTask+Private.h"
#import "ZincDownloadTask+Private.h"
#import "ZincBundle.h"
#import "ZincSource.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincManifest.h"
#import "ZincResource.h"
#import "NSData+Zinc.h"
#import "ZincEvent.h"
#import "ZincErrors.h"
#import "ZincJSONSerialization.h"
#import "ZincTaskActions.h"
#import "ZincHTTPRequestOperation+ZincContextInfo.h"

@implementation ZincManifestDownloadTask

- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input
{
    self = [super initWithRepo:repo resourceDescriptor:resource input:input];
    if (self) {
        self.title = NSLocalizedString(@"Updating Manifest", @"ZincManifestDownloadTask");
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
    NSError* error = nil;
    NSFileManager* fm = [[NSFileManager alloc] init];
    
    NSString* catalogID = [ZincBundle catalogIDFromBundleID:self.bundleID];
    
    NSArray* sources = [self.repo sourcesForCatalogID:catalogID];
    if (sources == nil || [sources count] == 0) {
        NSDictionary* info = @{@"catalogID": catalogID};
        error = ZincError(ZINC_ERR_NO_SOURCES_FOR_CATALOG);
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC() attributes:info]];
        return;
    }
    
    for (NSURL* source in sources) {
        
        NSString* bundleName = [ZincBundle bundleNameFromBundleID:self.bundleID];
        NSURLRequest* request = [source zincManifestURLRequestForBundleName:bundleName version:self.version];
        [self queueOperationForRequest:request outputStream:nil context:nil];
        
        [self.httpRequestOperation waitUntilFinished];
        if (self.isCancelled) return;

        if (!self.httpRequestOperation.hasAcceptableStatusCode) {
            [self addEvent:[ZincErrorEvent eventWithError:self.httpRequestOperation.error source:ZINC_EVENT_SRC() attributes:[self.httpRequestOperation zinc_contextInfo]]];
            continue;
        }
        
        [self addEvent:[ZincDownloadCompleteEvent downloadCompleteEventForURL:[request URL] size:self.bytesRead]];
        
        NSData* uncompressed = [self.httpRequestOperation.responseData zinc_gzipInflate];
        if (uncompressed == nil) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC() attributes:[self.httpRequestOperation zinc_contextInfo]]];
            continue;
        }
        
        id json = [ZincJSONSerialization JSONObjectWithData:uncompressed options:0 error:&error];
        if (json == nil) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC() attributes:[self.httpRequestOperation zinc_contextInfo]]];
            continue;
        }
        
        ZincManifest* manifest = [[ZincManifest alloc] initWithDictionary:json];
        NSData* data = [manifest jsonRepresentation:&error];
        if (data == nil) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
            continue;
        }
        
        NSString* path = [self.repo pathForManifestWithBundleID:self.bundleID version:manifest.version];
        
        // try remove existing. it shouldn't exist, but being defensive.
        [fm removeItemAtPath:path error:NULL];
        
        if (![data zinc_writeToFile:path atomically:YES createDirectories:YES skipBackup:YES error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
            continue;
        }
        
        [self.repo addManifest:manifest forBundleID:self.bundleID];
        
        self.finishedSuccessfully = YES;
        
        break; // make sure to break out of the loop when we finish successfully 
    }
}
@end
