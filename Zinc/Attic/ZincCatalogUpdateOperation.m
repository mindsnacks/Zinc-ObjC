//
//  ZincCatalogIndexUpdateTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/6/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincCatalogUpdateOperation.h"
#import "ZincTask+Private.h"
#import "ZincClient.h"
#import "ZincClient+Private.h"
#import "ZincSource.h"
#import "ZincCatalog.h"
#import "AFHTTPRequestOperation.h"
#import "NSData+Zinc.h"
#import "ZincEvent.h"
#import "ZincOperation.h"

@interface ZincCatalogUpdateOperation ()
@property (nonatomic, retain, readwrite) ZincSource* source;
@end

@implementation ZincCatalogUpdateOperation

@synthesize source = _source;

- (id) initWithTask:(ZincTask *)task source:(ZincSource*)source
{
    self = [super initWithTask:task];
    if (self) {
        self.source = source;
    }
    return self;
}

- (void) main
{
    NSError* error = nil;
    
    NSURLRequest* request = [self.source urlRequestForCatalogIndex];
    AFHTTPRequestOperation* requestOp = [self.task.client queuedHTTPRequestOperationForRequest:request];
    [requestOp setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:200]];
    [requestOp waitUntilFinished];
    if (![requestOp hasAcceptableStatusCode]) {
        // TODO: error;
        NSAssert(NO, @"request failed");
        return;
    }
    
    NSData* uncompressed = [requestOp.responseData zinc_gzipInflate];
    if (uncompressed == nil) {
        // TODO: real error
        NSAssert(NO, @"gunzip failed");
        return;
    }
    
    NSString* jsonString = [[[NSString alloc] initWithData:uncompressed encoding:NSUTF8StringEncoding] autorelease];
    ZincCatalog* catalog = [ZincCatalog catalogFromJSONString:jsonString error:&error];
    if (catalog == nil) {
        ZincEvent* event = [[[ZincErrorEvent alloc] initWithError:error source:self] autorelease];
        [self addEvent:event];
        return;
    }
    
    NSData* data = [[catalog jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        ZincEvent* event = [[[ZincErrorEvent alloc] initWithError:error source:self] autorelease];
        [self addEvent:event];
        return;
    }
    
    NSString* path = [self.task.client pathForCatalogIndex:catalog];
    ZincOperation* writeOp = [self.task.client queuedAtomicFileWriteOperationForData:data path:path];
    [writeOp waitUntilFinished];
    if (writeOp.error != nil) {
        ZincEvent* event = [[[ZincErrorEvent alloc] initWithError:writeOp.error source:self] autorelease];
        [self addEvent:event];
        return;
    } 
    
    [self.task.client registerSource:self.source forCatalog:catalog];
}

//
//- (BOOL) main
//{
//    NSError* error = nil;
//    
//    NSURLRequest* request = [self.source urlRequestForCatalogIndex];
//    AFHTTPRequestOperation* requestOp = [self.client queuedHTTPRequestOperationForRequest:request];
//    [requestOp setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:200]];
//    [requestOp waitUntilFinished];
//    if (![requestOp hasAcceptableStatusCode]) {
//        // TODO: error;
//        NSAssert(NO, @"request failed");
//        return NO;
//    }
//    
//    NSData* uncompressed = [requestOp.responseData zinc_gzipInflate];
//    if (uncompressed == nil) {
//        // TODO: real error
//        NSAssert(NO, @"gunzip failed");
//        return NO;
//    }
//    
//    NSString* jsonString = [[[NSString alloc] initWithData:uncompressed encoding:NSUTF8StringEncoding] autorelease];
//    ZincCatalog* catalog = [ZincCatalog catalogFromJSONString:jsonString error:&error];
//    if (catalog == nil) {
//        ZincEvent* event = [[[ZincErrorEvent alloc] initWithError:error source:self] autorelease];
//        [self addEvent:event];
//        return NO;
//    }
//    
//    NSData* data = [[catalog jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
//    if (data == nil) {
//        ZincEvent* event = [[[ZincErrorEvent alloc] initWithError:error source:self] autorelease];
//        [self addEvent:event];
//        return NO;
//    }
//    
//    NSString* path = [self.client pathForCatalogIndex:catalog];
//    ZincOperation* writeOp = [self.client queuedAtomicFileWriteOperationForData:data path:path];
//    [writeOp waitUntilFinished];
//    if (writeOp.error != nil) {
//        ZincEvent* event = [[[ZincErrorEvent alloc] initWithError:writeOp.error source:self] autorelease];
//        [self addEvent:event];
//        return NO;
//    } 
//    
//    [self.client registerSource:self.source forCatalog:catalog];
//    
//    return YES;
//}

//- (void) waitForOperation:(NSOperation*)op
//{
//    @synchronized(self) {
//        self.suboperation = op;
//        [op waitUntilFinished];
//        self.suboperation = nil;
//    }
//}

#if 0

- (BOOL) main2
{
    ZincOperationChain* chain = [[[ZincOperationChain alloc] init] autorelease];
    
    
    NSURLRequest* request = [self.source urlRequestForCatalogIndex];
    AFHTTPRequestOperation* requestOp = [self.client queuedHTTPRequestOperationForRequest:request];
    [requestOp setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    [chain addOperation:requestOp title:@"Getting Data" passFailBlock:^{
        if (![requestOp hasAcceptableStatusCode]) {
            // TODO: error;
            NSAssert(NO, @"request failed");
            return NO;
        }
        return YES;
    }];
    
    NSBlockOperation* op1 = [NSBlockOperation blockOperationWithBlock:^{

        NSError* error = nil;

        if (![requestOp hasAcceptableStatusCode]) {
            // TODO: error;
            NSAssert(NO, @"request failed");
            //return NO;
        }
        
        NSData* uncompressed = [requestOp.responseData zinc_gzipInflate];
        if (uncompressed == nil) {
            // TODO: real error
            NSAssert(NO, @"gunzip failed");
            //return NO;
        }
        
        NSString* jsonString = [[[NSString alloc] initWithData:uncompressed encoding:NSUTF8StringEncoding] autorelease];
        ZincCatalog* catalog = [ZincCatalog catalogFromJSONString:jsonString error:&error];
        if (catalog == nil) {
            ZincEvent* event = [[[ZincErrorEvent alloc] initWithError:error source:self] autorelease];
            [self addEvent:event];
            //return NO;
        }
        
        NSData* data = [[catalog jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
        if (data == nil) {
            ZincEvent* event = [[[ZincErrorEvent alloc] initWithError:error source:self] autorelease];
            [self addEvent:event];
            //return NO;
        }
    }];

        
        NSString* path = [self.client pathForCatalogIndex:catalog];
        ZincOperation* writeOp = [self.client queuedAtomicFileWriteOperationForData:data path:path];
        [writeOp waitUntilFinished];
        if (writeOp.error != nil) {
            ZincEvent* event = [[[ZincErrorEvent alloc] initWithError:writeOp.error source:self] autorelease];
            [self addEvent:event];
            //return NO;
        } 
        
        [self.client registerSource:self.source forCatalog:catalog];
        

    
    
    
//    NSString* jsonString = [[[NSString alloc] initWithData:uncompressed encoding:NSUTF8StringEncoding] autorelease];
//    ZincCatalog* catalog = [ZincCatalog catalogFromJSONString:jsonString error:&error];
//    if (catalog == nil) {
//        ZincEvent* event = [[[ZincErrorEvent alloc] initWithError:error source:self] autorelease];
//        [self addEvent:event];
//        return NO;
//    }
//    
//    NSData* data = [[catalog jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
//    if (data == nil) {
//        ZincEvent* event = [[[ZincErrorEvent alloc] initWithError:error source:self] autorelease];
//        [self addEvent:event];
//        return NO;
//    }
//    
//    NSString* path = [self.client pathForCatalogIndex:catalog];
//    ZincOperation* writeOp = [self.client queuedAtomicFileWriteOperationForData:data path:path];
//    [writeOp waitUntilFinished];
//    if (writeOp.error != nil) {
//        ZincEvent* event = [[[ZincErrorEvent alloc] initWithError:writeOp.error source:self] autorelease];
//        [self addEvent:event];
//        return NO;
//    } 
//    
//    [self.client registerSource:self.source forCatalog:catalog];
//    
//    return YES;
}

#endif

@end

