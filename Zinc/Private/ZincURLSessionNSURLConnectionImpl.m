//
//  ZincURLSessionImpl.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincURLSessionNSURLConnectionImpl.h"
#import "ZincHTTPURLConnectionOperation+ZincURLSessionTask.h"

@implementation ZincURLSessionNSURLConnectionImpl
{
    NSOperationQueue *_operationQueue;
}

- (instancetype)initWithOperationQueue:(NSOperationQueue *)opQueue
{
    NSParameterAssert(opQueue);
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

    if (completionHandler != NULL) {
        __weak typeof(op) weakOp = op;
        op.completionBlock = ^{
            __strong typeof(weakOp) strongOp = weakOp;
            completionHandler(strongOp.responseData, strongOp.response, strongOp.error);
        };
    }

    [_operationQueue addOperation:op];
    return op;
}

- (id<ZincURLSessionTask>)downloadTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler
{
    ZincHTTPURLConnectionOperation* op = [[ZincHTTPURLConnectionOperation alloc] initWithRequest:request];
    [self checkShouldExecuteOperationInBackground:op];

    NSString* tmpFormat = [NSTemporaryDirectory() stringByAppendingPathComponent:@"zinc-download.XXXXXXXX"];
    char* tmpCstring = mktemp((char*)[tmpFormat cStringUsingEncoding:NSUTF8StringEncoding]);
    NSString* tmpFile = @(tmpCstring);
    op.outputStream = [[NSOutputStream alloc] initToFileAtPath:tmpFile append:NO];

    if (completionHandler != NULL) {
        __weak typeof(op) weakOp = op;
        op.completionBlock = ^{
            __strong typeof(weakOp) strongOp = weakOp;
            NSURL* location = [NSURL fileURLWithPath:tmpFile];
            completionHandler(location, strongOp.response, strongOp.error);
        };
    }

    [_operationQueue addOperation:op];
    return op;
}

@end
