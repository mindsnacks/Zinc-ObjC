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

@property (readwrite) NSInteger bytesRead;
@property (readwrite) NSInteger totalBytesToRead;

@property (nonatomic, retain, readwrite) ZincHTTPRequestOperation* httpRequestOperation;

- (void) queueOperationForRequest:(NSURLRequest *)request
                     outputStream:(NSOutputStream *)outputStream
                          context:(id)context;

/**
 @discussion Internal method to build a dictionary of relevant information
 to be included with a ZincError
 */
- (NSDictionary*) getErrorContextInfo;

@end