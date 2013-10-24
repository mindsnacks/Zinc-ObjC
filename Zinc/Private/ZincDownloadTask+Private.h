//
//  ZincDownloadTask+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/30/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadTask.h"

@class ZincHTTPRequestOperation;

@interface ZincDownloadTask ()

@property (readwrite) long long bytesRead;
@property (readwrite) long long totalBytesToRead;

@property (nonatomic, strong, readwrite) ZincHTTPRequestOperation* httpRequestOperation;

- (void) queueOperationForRequest:(NSURLRequest *)request
                     outputStream:(NSOutputStream *)outputStream
                          context:(id)context;

@end