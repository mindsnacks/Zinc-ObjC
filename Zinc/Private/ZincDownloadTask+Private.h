//
//  ZincDownloadTask+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/30/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadTask.h"

@protocol ZincHTTPRequestOperation;

@interface ZincDownloadTask ()

@property (readwrite) long long bytesRead;
@property (readwrite) long long totalBytesToRead;

@property (nonatomic, strong, readwrite) id<ZincHTTPRequestOperation> httpRequestOperation;

- (void) queueOperationForRequest:(NSURLRequest *)request
                      downloadPath:(NSString *)downloadPath
                          context:(id)context;

@end