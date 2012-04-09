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
@synthesize totalBytesToRead = totalBytesToRead;

@synthesize context = _context;

- (ZincHTTPRequestOperation *) queuedOperationForRequest:(NSURLRequest *)request outputStream:(NSOutputStream *)outputStream context:(id)context
{
    ZincHTTPURLConnectionOperation* requestOp = [[[ZincHTTPURLConnectionOperation alloc] initWithRequest:request] autorelease];
//    ZincHTTPStreamOperation* requestOp = [[[ZincHTTPStreamOperation alloc] initWithURL:[request URL]] autorelease];
    requestOp.outputStream = outputStream;
    
    self.context = context;
    
    __block typeof(self) blockself = self;
    [requestOp setDownloadProgressBlock:^(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
        float progress = ((float)totalBytesRead/totalBytesExpectedToRead*100);
//        ZINC_DEBUG_LOG(@"%@   %d/%d = %d%%", [request URL], totalBytesRead, totalBytesExpectedToRead, (int)progress);
        
        blockself.bytesRead = totalBytesRead;
        blockself.totalBytesToRead = totalBytesExpectedToRead;
        
        [blockself addEvent:[ZincDownloadProgressEvent downloadProgressEventForURL:request.URL withProgress:progress context:context]];
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
    return self.totalBytesToRead;
}

- (void)dealloc
{
    [_context release];
    
    [super dealloc];
}

@end
