//
//  ZincDownloadTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/30/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadTask.h"
#import "ZincDownloadTask+Private.h"
#import "ZincHTTPRequestOperation.h"
#import "ZincEvent.h"
#import "ZincHTTPURLConnectionOperation.h"
#import "ZincHTTPStreamOperation.h"

@interface ZincDownloadTask()
@property (nonatomic, retain, readwrite) id context;
@end

@implementation ZincDownloadTask

@synthesize bytesRead = _bytesRead;
@synthesize totalBytesToRead = _totalBytesToRead;

@synthesize context = _context;

- (ZincHTTPRequestOperation *) queuedOperationForRequest:(NSURLRequest *)request outputStream:(NSOutputStream *)outputStream context:(id)context
{
    ZincHTTPURLConnectionOperation* requestOp = [[[ZincHTTPURLConnectionOperation alloc] initWithRequest:request] autorelease];
    
    requestOp.outputStream = outputStream;
    
    self.context = context;
    
    __block typeof(self) blockself = self;
//    __block float lastNotifiedProgressRounded = -1.0f;
    
    static const NSTimeInterval minTimeOffsetBetweenEventSends = 0.05f;
    __block NSTimeInterval lastTimeEventSentDate = 0;
    
    [requestOp setDownloadProgressBlock:^(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
        
//        blockself.bytesRead = totalBytesRead;
//        blockself.totalBytesToRead = totalBytesExpectedToRead;
        
//        [blockself updateCurrentBytes:totalBytesRead totalBytes:totalBytesExpectedToRead];

//        float newProgress = ((float)totalBytesRead/totalBytesExpectedToRead);
//        float newProgressRounded = roundf(100 * newProgress) / 100;
        
        NSTimeInterval currentDate = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval timeSinceLastEventSent = currentDate - lastTimeEventSentDate;
        
//        BOOL progressIncreasedSinceLastNotification = newProgressRounded != lastNotifiedProgressRounded;
        BOOL enoughTimePassedSinceLastNotification = timeSinceLastEventSent >= minTimeOffsetBetweenEventSends;
        
        // Decrease the amount of events sent by only sending significant value changes with a minimum time offset
//        if (progressIncreasedSinceLastNotification && enoughTimePassedSinceLastNotification)
        if (enoughTimePassedSinceLastNotification)

        {
//            lastNotifiedProgressRounded = newProgressRounded;
            lastTimeEventSentDate = currentDate;
                        
//            blockself.bytesRead = totalBytesRead;
//            blockself.totalBytesToRead = totalBytesExpectedToRead;
            
            [blockself updateCurrentBytes:totalBytesRead totalBytes:totalBytesExpectedToRead];
            
            //[blockself addEvent:[ZincDownloadProgressEvent downloadProgressEventForURL:request.URL withProgress:newProgress context:context]];
        }
    }];
    
    [self addEvent:[ZincDownloadBeginEvent downloadBeginEventForURL:request.URL]];
    
    [self addOperation:requestOp];
    
    return requestOp;
}

- (NSInteger) currentProgressValue
{
    return self.bytesRead;
}

- (NSInteger) maxProgressValue
{
    return MAX(self.totalBytesToRead, self.bytesRead);
}

- (void) updateCurrentBytes:(NSInteger)currentBytes totalBytes:(NSInteger)totalBytes
{
    [self willChangeValueForKey:@"currentProgressValue"];
    [self willChangeValueForKey:@"maxProgressValue"];
    self.bytesRead = currentBytes;
    self.totalBytesToRead = totalBytes;
    [self didChangeValueForKey:@"currentProgressValue"];
    [self didChangeValueForKey:@"maxProgressValue"];
}

//- (void) setBytesRead:(NSInteger)bytesRead
//{
//    [self willChangeValueForKey:@"currentProgressValue"];
//    _bytesRead = bytesRead;
//    [self didChangeValueForKey:@"currentProgressValue"];
//}
//
//- (void) setTotalBytesToRead:(NSInteger)totalBytesToRead
//{
//    [self willChangeValueForKey:@"maxProgressValue"];
//    _totalBytesToRead = totalBytesToRead;
//    [self didChangeValueForKey:@"maxProgressValue"];
//}

- (void)dealloc
{
    [_context release];
    [super dealloc];
}

@end
