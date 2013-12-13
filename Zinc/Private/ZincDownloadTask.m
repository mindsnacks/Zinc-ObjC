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


@interface ZincDownloadTask()
@property (nonatomic, strong, readwrite) id context;
@end

@implementation ZincDownloadTask

+ (NSString *)action
{
    return ZincTaskActionUpdate;
}

- (void) queueOperationForRequest:(NSURLRequest *)request downloadPath:(NSString *)downloadPath context:(id)context completion:(dispatch_block_t)completion
{
    NSParameterAssert(request);
    NSParameterAssert(completion);
    NSAssert(self.URLSessionTask == nil || [self.URLSessionTask isFinished], @"URLSessionTask already enqueued");

    id<ZincURLSessionTask> requestTask = nil;

    __weak typeof(self) weakself = self;

    if (downloadPath != nil) {
        requestTask = [self.repo.URLSession downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            __strong typeof(weakself) strongself = weakself;
            if (error == nil) {
                NSFileManager* fm = [[NSFileManager alloc] init];
                NSURL* downloadURL = [NSURL fileURLWithPath:downloadPath];
                NSError* moveError = nil;
                if (![fm moveItemAtURL:location toURL:downloadURL error:&moveError]) {
                    [strongself addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
                }
            }
            completion();
        }];

    } else {
        requestTask = [self.repo.URLSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            __strong typeof(weakself) strongself = weakself;
            strongself.responseData = data;
            completion();
        }];
    }

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
