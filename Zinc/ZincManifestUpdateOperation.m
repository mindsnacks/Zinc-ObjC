//
//  ZincManifestUpdateOperation.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincManifestUpdateOperation.h"
#import "ZincBundle.h"
#import "ZincSource.h"
#import "ZincClient.h"
#import "ZincClient+Private.h"
#import "AFHTTPRequestOperation.h"
#import "ZincAtomicFileWriteOperation.h"
#import "NSData+Zinc.h"
#import "ZincEvent.h"
#import "KSJSON.h"

@implementation ZincManifestUpdateOperation

@synthesize bundleId = _bundleId;
@synthesize version = _version;

- (id)initWithClient:(ZincClient *)client bundleIdentifier:(NSString*)bundleId version:(ZincVersion)version
{    
    self = [super initWithClient:client];
    if (self) {
        self.bundleId = bundleId;
        self.version = version;
        // TODO: title?
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
    NSError* error = nil;
    
    NSString* catalogId = [ZincBundle sourceFromBundleIdentifier:self.bundleId];
    NSString* bundleName = [ZincBundle nameFromBundleIdentifier:self.bundleId];
    ZincSource* source = [[self.client sourcesForCatalogIdentifier:catalogId] lastObject]; // TODO: fix lastObject
    if (source == nil) {
        ZINC_DEBUG_LOG(@"source is nil");
        // TODO: better error
        return;
    }
    
    NSURLRequest* request = [source urlRequestForBundleName:bundleName version:self.version];
    if (request == nil) {
        // TODO: better error
        NSAssert(0, @"request is nil");
        return;
    }
    
//    AFHTTPRequestOperation* requestOp = [self.client queuedHTTPRequestOperationForRequest:request];
    AFHTTPRequestOperation* requestOp = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    [requestOp setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:200]];
    [self.client addOperation:requestOp];
    [requestOp waitUntilFinished];
    if (!requestOp.hasAcceptableStatusCode) {
        [self addEvent:[ZincErrorEvent eventWithError:requestOp.error source:self]];
        return;
    }
    
    NSData* uncompressed = [requestOp.responseData zinc_gzipInflate];
    if (uncompressed == nil) {
        // TODO: set error
        NSAssert(NO, @"gunzip failed");
        return;
    }
    
    NSString* jsonString = [[[NSString alloc] initWithData:uncompressed encoding:NSUTF8StringEncoding] autorelease];
    id json = [KSJSON deserializeString:jsonString error:&error];
    if (json == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:json] autorelease];
    NSData* data = [[manifest jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    NSString* path = [self.client pathForManifestWithBundleIdentifier:self.bundleId version:manifest.version];
    ZincAtomicFileWriteOperation* writeOp = [[[ZincAtomicFileWriteOperation alloc] initWithData:data path:path] autorelease];
    [self.client addOperation:writeOp];
    [writeOp waitUntilFinished];
    if (writeOp.error != nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    [self.client registerManifest:manifest forBundleId:self.bundleId];
    
    self.finishedSuccessfully = YES;
}
@end
