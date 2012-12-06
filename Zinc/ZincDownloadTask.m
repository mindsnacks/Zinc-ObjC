//
//  ZincDownloadTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/30/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadTask.h"
#import "ZincTask+Private.h"
#import "ZincDownloadTask+Private.h"
#import "ZincHTTPRequestOperation.h"
#import "ZincEvent.h"
#import "ZincHTTPRequestOperation.h"
#import "ZincTaskActions.h"
#import "ZincRepo.h"

@interface ZincDownloadTask()
@property (nonatomic, retain, readwrite) id context;
@end

@implementation ZincDownloadTask


+ (NSString *)action
{
    return ZincTaskActionUpdate;
}

- (ZincHTTPRequestOperation *) queuedOperationForRequest:(NSURLRequest *)request outputStream:(NSOutputStream *)outputStream context:(id)context
{
    ZincHTTPRequestOperation* requestOp = [[[ZincHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    
    if (outputStream != nil) {
        requestOp.outputStream = outputStream;
    }
    
    if (self.repo.executeTasksInBackgroundEnabled) {
        [requestOp setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    }
    
    self.context = context;
    
    static const NSTimeInterval minTimeOffsetBetweenEventSends = 0.25f;
    __block NSTimeInterval lastTimeEventSentDate = 0;
    
    [requestOp setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        NSTimeInterval currentDate = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval timeSinceLastEventSent = currentDate - lastTimeEventSentDate;
        
        BOOL enoughTimePassedSinceLastNotification = timeSinceLastEventSent >= minTimeOffsetBetweenEventSends;
        if (enoughTimePassedSinceLastNotification)
        {
            lastTimeEventSentDate = currentDate;
            [self updateCurrentBytes:totalBytesRead totalBytes:totalBytesExpectedToRead];
        }
    }];
    
    [self addEvent:[ZincDownloadBeginEvent downloadBeginEventForURL:request.URL]];
    
    [self addOperation:requestOp];
    
    return requestOp;
}

- (long long) currentProgressValue
{
    return self.bytesRead;
}

- (long long) maxProgressValue
{
    return MAX(self.totalBytesToRead, self.bytesRead);
}

- (void) updateCurrentBytes:(NSInteger)currentBytes totalBytes:(NSInteger)totalBytes
{
    self.bytesRead = currentBytes;
    self.totalBytesToRead = totalBytes;
}

- (void)dealloc
{
    [_context release];
    [super dealloc];
}

@end
