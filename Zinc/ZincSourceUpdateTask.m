//
//  ZincCatalogUpdateOperation2.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincSourceUpdateTask.h"
#import "ZincTask+Private.h"
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
#import "ZincHTTPRequestOperation+ZincContextInfo.h"

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


- (NSURL*) sourceURL
{
    return self.resource;
}

- (void) main
{
    NSError* error = nil;
    
    NSURLRequest* request = [self.sourceURL urlRequestForCatalogIndex];
    ZincHTTPRequestOperation* requestOp = [[ZincHTTPRequestOperation alloc] initWithRequest:request];
    [self queueChildOperation:requestOp];
    
    [requestOp waitUntilFinished];
    if (self.isCancelled) return;
    
    if (![requestOp hasAcceptableStatusCode]) {
        [self addEvent:[ZincErrorEvent eventWithError:requestOp.error source:ZINC_EVENT_SRC() attributes:[requestOp zinc_contextInfo]]];
        return;
    }
    
    if (self.isCancelled) return;
    
    NSData* uncompressed = [requestOp.responseData zinc_gzipInflate];
    if (uncompressed == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC() attributes:[requestOp zinc_contextInfo]]];
        return;
    }
    
    ZincCatalog* catalog = [ZincCatalog catalogFromJSONData:uncompressed error:&error];
    if (catalog == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC() attributes:[requestOp zinc_contextInfo]]];
        return;
    }
    
    NSData* data = [catalog jsonRepresentation:&error];
    if (data == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
        return;
    }
    
    NSURL* catalogRes = [NSURL zincResourceForCatalogWithId:catalog.identifier];
    ZincTaskDescriptor* taskDesc = [ZincCatalogUpdateTask taskDescriptorForResource:catalogRes];
    
    ZincTask* catalogTask = [self queueChildTaskForDescriptor:taskDesc input:catalog];
    
    [catalogTask waitUntilFinished];
    if (self.isCancelled) return;
    
    if (!catalogTask.finishedSuccessfully) {
        return;
    }
    
    [self.repo registerSource:self.sourceURL forCatalog:catalog];
    
    self.finishedSuccessfully = YES;
}

@end
