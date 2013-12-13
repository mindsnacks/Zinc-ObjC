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

- (void)checkShouldExecuteOperationInBackground:(ZincHTTPURLConnectionOperation *)op
{
#if TARGET_OS_IPHONE && TARGET_IPHONE_SIMULATOR
    BOOL shouldExecuteInBackground = NO;
    if (self.backgroundTaskDelegate) {
        shouldExecuteInBackground = [self.backgroundTaskDelegate urlSession:self shouldExecuteOperationsInBackground:op];
    } else {
        shouldExecuteInBackground = YES;
    }

    if (shouldExecuteInBackground) {
        [op setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    }
#endif
}

- (id<ZincURLSessionTask>)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
    ZincHTTPURLConnectionOperation* op = [[ZincHTTPURLConnectionOperation alloc] initWithRequest:request];
    [self checkShouldExecuteOperationInBackground:op];

    __weak typeof(op) weakOp = op;
    op.completionBlock = ^{
        __strong typeof(weakOp) strongOp = weakOp;
        completionHandler(strongOp.responseData, strongOp.response, strongOp.error);
    };

    [_operationQueue addOperation:op];
    return op;
}

- (id<ZincURLSessionTask>)downloadTaskWithRequest:(NSURLRequest *)request destinationPath:(NSString *)destPath completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler
{
    ZincHTTPURLConnectionOperation* op = [[ZincHTTPURLConnectionOperation alloc] initWithRequest:request];
    [self checkShouldExecuteOperationInBackground:op];

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
