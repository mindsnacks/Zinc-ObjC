//
//  ZincCatalogUpdateOperation2.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincCatalogUpdateOperation2.h"
#import "AFHTTPRequestOperation.h"
#import "NSData+Zinc.h"
#import "ZincCatalog.h"
#import "ZincClient.h"
#import "ZincClient+Private.h"
#import "ZincEvent.h"
#import "ZincSource.h"
#import "ZincAtomicFileWriteOperation.h"

@interface ZincCatalogUpdateOperation2 ()
@property (nonatomic, retain, readwrite) ZincSource* source;
@end

@implementation ZincCatalogUpdateOperation2

@synthesize source = _source;

- (id) initWithClient:(ZincClient *)client source:(ZincSource*)source
{
    self = [super initWithClient:client];
    if (self) {
        self.source = source;
        self.title = @"Updating Catalog"; // TODO: localization
    }
    return self;
}

- (void)dealloc 
{
    self.source = nil;
    [super dealloc];
}

- (NSString*) key
{
    return [NSString stringWithFormat:@"%@:%@",
            NSStringFromClass([self class]),
            [self.source.url absoluteString]];
}

- (void) main
{
    NSError* error = nil;
    
    NSURLRequest* request = [self.source urlRequestForCatalogIndex];
    //AFHTTPRequestOperation* requestOp = [self.client queuedHTTPRequestOperationForRequest:request];
    AFHTTPRequestOperation* requestOp = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    [requestOp setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:200]];
    [self addOperation:requestOp];
    [requestOp waitUntilFinished];
    if (![requestOp hasAcceptableStatusCode]) {
        // TODO: error;
        NSAssert(NO, @"request failed");
        return;
    }
    
    if (self.isCancelled) return;
    
    NSData* uncompressed = [requestOp.responseData zinc_gzipInflate];
    if (uncompressed == nil) {
        // TODO: real error
        NSAssert(NO, @"gunzip failed");
        return;
    }
    
    NSString* jsonString = [[[NSString alloc] initWithData:uncompressed encoding:NSUTF8StringEncoding] autorelease];
    ZincCatalog* catalog = [ZincCatalog catalogFromJSONString:jsonString error:&error];
    if (catalog == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    NSData* data = [[catalog jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    NSString* path = [self.client pathForCatalogIndex:catalog];
    ZincAtomicFileWriteOperation* writeOp = [[[ZincAtomicFileWriteOperation alloc] initWithData:data path:path] autorelease];
    [self addOperation:writeOp];
    [writeOp waitUntilFinished];
    if (writeOp.error != nil) {
        [self addEvent:[ZincErrorEvent eventWithError:writeOp.error source:self]];
        return;
    } 
    
    [self.client registerSource:self.source forCatalog:catalog];
    
    self.finishedSuccessfully = YES;
}

@end
