//
//  ZincCatalogUpdateOperation2.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincSourceUpdateTask.h"

#import "ZincInternals.h"

#import "ZincTask+Private.h"
#import "ZincRepo+Private.h"
#import "ZincTaskActions.h"
#import "ZincEventHelpers.h"


@implementation ZincSourceUpdateTask
{
    BOOL _isExecuting;
    BOOL _isFinished;
}

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

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return _isExecuting;
}

- (BOOL)isFinished
{
    return _isFinished;
}

- (void)start
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    _isExecuting = YES;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];

    NSURLRequest* request = [self.sourceURL urlRequestForCatalogIndex];

    [self.repo.URLSession dataTaskWithRequest:request
                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                BOOL success = [self handleResultFromRequest:request response:response data:data error:error];

                                [self completeWithSucess:success];
                            }];
}

- (void)completeWithSucess:(BOOL)success
{
    self.finishedSuccessfully = success;

    [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    _isFinished = YES;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
}

- (BOOL)handleResultFromRequest:(NSURLRequest *)request response:(NSURLResponse *)response data:(NSData *)responseData error:(NSError *)error
{
    if (self.isCancelled) return NO;

    NSDictionary* eventAttrs = [ZincEventHelpers attributesForRequest:request andResponse:response];

    if (error != nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC() attributes:eventAttrs]];
        return NO;
    }

    if (self.isCancelled) return NO;

    NSData* uncompressed = [responseData zinc_gzipInflate];
    if (uncompressed == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC() attributes:eventAttrs]];
        return NO;
    }

    ZincCatalog* catalog = [ZincCatalog catalogFromJSONData:uncompressed error:&error];
    if (catalog == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC() attributes:eventAttrs]];
        return NO;
    }

    NSError *jsonError = nil;
    NSData* jsonData = [catalog jsonRepresentation:&jsonError];
    if (jsonData == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:jsonError source:ZINC_EVENT_SRC()]];
        return NO;
    }

    NSURL* catalogRes = [NSURL zincResourceForCatalogWithId:catalog.identifier];
    ZincTaskDescriptor* taskDesc = [ZincCatalogUpdateTask taskDescriptorForResource:catalogRes];

    ZincTask* catalogTask = [self queueChildTaskForDescriptor:taskDesc input:catalog];

    [catalogTask waitUntilFinished];
    if (self.isCancelled) return NO;

    if (!catalogTask.finishedSuccessfully) {
        return NO;
    }

    [self.repo registerSource:self.sourceURL forCatalog:catalog];

    return YES;
}

@end
