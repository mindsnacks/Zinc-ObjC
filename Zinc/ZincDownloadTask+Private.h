//
//  ZincDownloadTask+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/30/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadTask.h"
#import "AFHTTPRequestOperation.h"

@interface ZincDownloadTask ()

@property (readwrite) NSInteger bytesRead;
@property (readwrite) NSInteger totalBytesToRead;

- (AFHTTPRequestOperation *) queuedOperationForRequest:(NSURLRequest *)request
                                          outputStream:(NSOutputStream *)outputStream;

@end