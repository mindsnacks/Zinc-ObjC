//
//  ZincHTTPRequestOperation+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 2/29/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincHTTPRequestOperation.h"

@interface ZincHTTPRequestOperation ()

@property (readwrite, nonatomic, retain) NSData *responseData;
@property (readwrite, nonatomic, retain) NSMutableData *dataAccumulator;
@property (readwrite, nonatomic, assign) NSInteger totalBytesRead;
@property (readwrite, nonatomic, copy) ZincURLConnectionOperationProgressBlock downloadProgress;
@property (readonly, nonatomic, assign) BOOL hasContent;

- (void) createDataAccumulatorForContentLength:(NSUInteger)contentLength;

@end