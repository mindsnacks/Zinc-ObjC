//
//  ZincCatalogUpdateOperation2.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincSourceUpdateTask.h"
#import "ZincHTTPURLConnectionOperation.h"
#import "NSData+Zinc.h"
#import "ZincCatalog.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincEvent.h"
#import "ZincSource.h"
#import "ZincCatalogUpdateTask.h"
#import "ZincResource.h"
#import "ZincErrors.h"
#import "ZincTaskActions.h"

@implementation ZincSourceUpdateTask

+ (NSString *)action
{
    return ZincTaskActionUpdate;
}

- (id) initWithRepo:(ZincRepo *)repo resourceDescriptor:(NSURL *)resource input:(id)input
{
    self = [super initWithRepo:repo resourceDescriptor:resource input:input];
    if (self) {
        self.title = @"Updating Source"; // TODO: localization
    }
    return self;
}

- (void)dealloc 
{
    [super dealloc];
}

- (NSURL*) sourceURL
{
    return self.resource;
}

- (void) main
{
    NSError* error = nil;
    
    NSURLRequest* request = [self.sourceURL urlRequestForCatalogIndex];
    ZincHTTPURLConnectionOperation* requestOp = [[[ZincHTTPURLConnectionOperation alloc] initWithRequest:request] autorelease];
    [requestOp setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:200]];
    [self addOperation:requestOp];
    [requestOp waitUntilFinished];
    if (![requestOp hasAcceptableStatusCode]) {
        [self addEvent:[ZincErrorEvent eventWithError:requestOp.error source:self]];
        return;
    }
    
    if (self.isCancelled) return;
    
    NSData* uncompressed = [requestOp.responseData zinc_gzipInflate];
    if (uncompressed == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:ZincError(ZINC_ERR_DECOMPRESS_FAILED) source:self]];
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
    
    NSURL* catalogRes = [NSURL zincResourceForCatalogWithId:catalog.identifier];
    ZincTaskDescriptor* taskDesc = [ZincCatalogUpdateTask taskDescriptorForResource:catalogRes];
    
    ZincTask* catalogTask = [self queueSubtaskForDescriptor:taskDesc input:catalog];
    [catalogTask waitUntilFinished];
    
    if (!catalogTask.finishedSuccessfully) {
        return;
    }
    
    [self.repo registerSource:self.sourceURL forCatalog:catalog];
    
    self.finishedSuccessfully = YES;
}

@end
