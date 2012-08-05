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
#import "ZincTaskActions.h"

@interface ZincDownloadTask()
@property (nonatomic, retain, readwrite) id context;
@end

@implementation ZincDownloadTask

@synthesize bytesRead = _bytesRead;
@synthesize totalBytesToRead = _totalBytesToRead;

@synthesize context = _context;

+ (NSString *)action
{
    return ZincTaskActionUpdate;
}

- (ZincHTTPRequestOperation *) queuedOperationForRequest:(NSURLRequest *)request outputStream:(NSOutputStream *)outputStream context:(id)context
{
    ZincHTTPURLConnectionOperation* requestOp = [[[ZincHTTPURLConnectionOperation alloc] initWithRequest:request] autorelease];
    
    requestOp.outputStream = outputStream;
    
    self.context = context;
    
    __block typeof(self) blockself = self;
    
    static const NSTimeInterval minTimeOffsetBetweenEventSends = 0.5f;
    __block NSTimeInterval lastTimeEventSentDate = 0;
    
    [requestOp setDownloadProgressBlock:^(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
        
        NSTimeInterval currentDate = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval timeSinceLastEventSent = currentDate - lastTimeEventSentDate;
        
        BOOL enoughTimePassedSinceLastNotification = timeSinceLastEventSent >= minTimeOffsetBetweenEventSends;
        if (enoughTimePassedSinceLastNotification)
        {
            lastTimeEventSentDate = currentDate;
            [blockself updateCurrentBytes:totalBytesRead totalBytes:totalBytesExpectedToRead];
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

- (void)dealloc
{
    [_context release];
    [super dealloc];
}

@end
