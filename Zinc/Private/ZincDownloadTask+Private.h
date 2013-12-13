//
//  ZincDownloadTask+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/30/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadTask.h"

@protocol ZincURLSessionTask;

@interface ZincDownloadTask ()

@property (nonatomic, strong, readwrite) id<ZincURLSessionTask> URLSessionTask;

- (void) queueOperationForRequest:(NSURLRequest *)request
                      downloadPath:(NSString *)downloadPath
                          context:(id)context;

@end