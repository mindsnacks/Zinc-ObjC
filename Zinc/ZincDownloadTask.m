//
//  ZincDownloadTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/30/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadTask.h"
#import "ZincDownloadTask+Private.h"
#import "ZincAFHTTPRequestOperation.h"
#import "ZincEvent.h"

@implementation ZincDownloadTask

@synthesize bytesRead = _bytesRead;
@synthesize totalBytesToRead = totalBytesToRead;

- (ZincAFHTTPRequestOperation *) queuedOperationForRequest:(NSURLRequest *)request outputStream:(NSOutputStream *)outputStream
{
    ZincAFHTTPRequestOperation* requestOp = [[[ZincAFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    requestOp.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:200];
    requestOp.outputStream = outputStream;
    
    __block typeof(self) blockself = self;
    [requestOp setDownloadProgressBlock:^(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
        //ZINC_DEBUG_LOG(@"%@   %d/%d = %d%%", [request URL], totalBytesRead, totalBytesExpectedToRead, (int)((float)totalBytesRead/totalBytesExpectedToRead*100));
        blockself.bytesRead = totalBytesRead;
        blockself.totalBytesToRead = totalBytesExpectedToRead;
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


@end
