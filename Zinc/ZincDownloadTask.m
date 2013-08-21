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
#import "ZincRepo.h"
#import "ZincHTTPRequestOperation.h"

// TODO: break this dependency?
#import "ZincRepo+Private.h"

@interface ZincDownloadTask()
@property (nonatomic, strong, readwrite) id context;
@property (atomic, readwrite) BOOL trackingProgress;
@end

@implementation ZincDownloadTask


+ (NSString *)action
{
    return ZincTaskActionUpdate;
}

- (void) queueOperationForRequest:(NSURLRequest *)request outputStream:(NSOutputStream *)outputStream context:(id)context
{
    NSAssert(self.httpRequestOperation == nil || [self.httpRequestOperation isFinished], @"operation already enqueued");
    
    ZincHTTPRequestOperation* requestOp = [[ZincHTTPRequestOperation alloc] initWithRequest:request];
    
    if (outputStream != nil) {
        requestOp.outputStream = outputStream;
    }
    
    if (self.repo.taskManager.executeTasksInBackgroundEnabled) { // TODO: break this dependency?
        [requestOp setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    }
    
    self.context = context;
    
    [self addEvent:[ZincDownloadBeginEvent downloadBeginEventForURL:request.URL]];
    
    self.httpRequestOperation = requestOp;
    
    [self queueChildOperation:requestOp];
}

- (void)addProgressTrackingIfNeeded
{
    @synchronized(self) {
        if (self.trackingProgress) return;
        self.trackingProgress = YES;
    }
    
    static const NSTimeInterval minTimeOffsetBetweenEventSends = 0.25f;
    __block NSTimeInterval lastTimeEventSentDate = 0;
    __weak typeof(self) weakself = self;
    
    [self.httpRequestOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {

        __weak typeof(weakself) strongself = weakself;

        NSTimeInterval currentDate = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval timeSinceLastEventSent = currentDate - lastTimeEventSentDate;
        
        BOOL enoughTimePassedSinceLastNotification = timeSinceLastEventSent >= minTimeOffsetBetweenEventSends;
        BOOL downloadCompleted = totalBytesRead == totalBytesExpectedToRead;
        if (enoughTimePassedSinceLastNotification || downloadCompleted)
        {
            lastTimeEventSentDate = currentDate;
            [strongself updateCurrentBytes:totalBytesRead totalBytes:totalBytesExpectedToRead];
        }
    }];
}

- (long long) currentProgressValue
{
    [self addProgressTrackingIfNeeded];
    return self.bytesRead;
}

- (long long) maxProgressValue
{
    [self addProgressTrackingIfNeeded];
    return MAX(self.totalBytesToRead, self.bytesRead);
}

- (void) updateCurrentBytes:(NSInteger)currentBytes totalBytes:(NSInteger)totalBytes
{
    self.bytesRead = currentBytes;
    self.totalBytesToRead = totalBytes;
}

- (void)dealloc
{
    [self.httpRequestOperation waitUntilFinished];
}

@end
