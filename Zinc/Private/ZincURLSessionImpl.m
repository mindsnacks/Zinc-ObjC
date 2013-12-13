//
//  ZincURLSessionImpl.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincURLSessionImpl.h"
#import "ZincHTTPURLConnectionOperation+ZincURLSessionTask.h"

@implementation ZincURLSession
{
    NSOperationQueue *_operationQueue;
}

- (instancetype)initWithOperationQueue:(NSOperationQueue *)opQueue
{
    self = [super init];
    if (self) {
        _operationQueue = opQueue;
    }
    return self;
}

- (id<ZincURLSessionTask>)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{

    ZincHTTPURLConnectionOperation* op = [[ZincHTTPURLConnectionOperation alloc] initWithRequest:request];

    //#if TARGET_OS_IPHONE && TARGET_IPHONE_SIMULATOR
//#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
//    if ([self shouldExecuteOperationInBackground:requestOp]) {
//        [urlConnectionOp setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
//    }
//#endif

    __weak typeof(op) weakOp = op;
    op.completionBlock = ^{
        __strong typeof(weakOp) strongOp = weakOp;
        completionHandler(strongOp.responseData, strongOp.response, strongOp.error);
    };

    [_operationQueue addOperation:op];
    return op;
}

- (id<ZincURLSessionTask>)downloadTaskWithRequest:(NSURLRequest *)request
{
    return nil;
}

- (id<ZincURLSessionTask>)downloadTaskWithRequest:(NSURLRequest *)request destinationPath:(NSString *)destPath completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler
{

    ZincHTTPURLConnectionOperation* op = [[ZincHTTPURLConnectionOperation alloc] initWithRequest:request];

    if (destPath != nil) {
        op.outputStream = [[NSOutputStream alloc] initToFileAtPath:destPath append:NO];
    }

    __weak typeof(op) weakOp = op;
    op.completionBlock = ^{
        if (completionHandler != NULL) {
            __strong typeof(weakOp) strongOp = weakOp;
            NSURL *location = nil;
            if (destPath) {
                location =  [NSURL fileURLWithPath:destPath];;
            }
            completionHandler(location, strongOp.response, strongOp.error);
        }
    };

    [_operationQueue addOperation:op];
    return op;
}


@end
