//
//  ZincHTTPURLConnectionOperation+ZincURLSessionTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincHTTPURLConnectionOperation+ZincURLSessionTask.h"

@implementation ZincHTTPURLConnectionOperation (ZincURLSessionTask)

// to suppress a warning in iOS 6
@dynamic error;
@dynamic response;

- (NSURLRequest *)originalRequest
{
    return self.request;
}

- (NSURLRequest *)currentRequest
{
    return self.request;
}

- (int64_t)countOfBytesReceived
{
    return self.totalBytesRead;
}

- (int64_t)countOfBytesExpectedToReceive
{
    return self.response.expectedContentLength;
}

@end
