//
//  ZincHTTPRequestOperationFactory.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincHTTPRequestOperationFactory.h"

#import "ZincHTTPURLConnectionOperation.h"

@implementation ZincHTTPRequestOperationFactory
{
    BOOL _NSURLSessionAvailable;
}

- (id)init
{
    self = [super init];
    if (self) {
        // TODO: determine if we're on iOS 6 or 7
        _NSURLSessionAvailable = NO;
    }
    return self;
}

- (BOOL)shouldExecuteOperationInBackground:(id<ZincHTTPRequestOperation>)op
{
    if (self.delegate) {
        return [self.delegate HTTPRequestOperationFactory:self
                      shouldExecuteOperationsInBackground:op];
    } else {
       return YES;
    }
}

- (id<ZincHTTPRequestOperation>)operationForRequest:(NSURLRequest *)request
{
    id <ZincHTTPRequestOperation> requestOp = nil;

    if (_NSURLSessionAvailable) {

        NSParameterAssert(nil);

    } else {

        ZincHTTPURLConnectionOperation* urlConnectionOp = [[ZincHTTPURLConnectionOperation alloc] initWithRequest:request];

        //#if TARGET_OS_IPHONE && TARGET_IPHONE_SIMULATOR
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        if ([self shouldExecuteOperationInBackground:requestOp]) {
            [urlConnectionOp setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
        }
#endif

        requestOp = urlConnectionOp;
    }

    return requestOp;
}

@end
