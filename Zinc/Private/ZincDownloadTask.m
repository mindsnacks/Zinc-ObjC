//
//  ZincDownloadTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/30/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadTask+Private.h"

#import "ZincInternals.h"
#import "ZincTask+Private.h"
#import "ZincTaskActions.h"
#import "ZincRepo+Private.h"
#import "ZincHTTPRequestOperation.h"
#import "ZincHTTPRequestOperationFactory.h"


@interface ZincDownloadTask()
@property (nonatomic, strong, readwrite) id context;
@end

@implementation ZincDownloadTask

+ (NSString *)action
{
    return ZincTaskActionUpdate;
}

- (void) queueOperationForRequest:(NSURLRequest *)request downloadPath:(NSString *)downloadPath context:(id)context
{
    NSAssert(self.URLSessionTask == nil || [self.URLSessionTask isFinished], @"URLSessionTask already enqueued");

    id<ZincURLSessionTask> requestTask = [self.repo.URLSession downloadTaskWithRequest:request destinationPath:downloadPath completionHandler:nil];

    self.context = context;

    [self addEvent:[ZincDownloadBeginEvent downloadBeginEventForURL:request.URL]];

    self.URLSessionTask = requestTask;

    // TODO: is this needed?
    //    [self queueChildOperation:requestOp];
}

- (long long) currentProgressValue
{
    if ([self isFinished]) {
        return [self maxProgressValue];
    }

    return [self.URLSessionTask countOfBytesReceived];
}

- (long long) maxProgressValue
{
    if (self.URLSessionTask.response != nil) {
        return [self.URLSessionTask countOfBytesExpectedToReceive];
    }
    return [self isFinished] ? 0 : ZincProgressNotYetDetermined;
}

- (long long)bytesRead
{
    return [self currentProgressValue];
}


@end
