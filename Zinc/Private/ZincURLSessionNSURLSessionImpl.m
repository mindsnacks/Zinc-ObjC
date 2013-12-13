//
//  ZincURLSessionNSURLSessionImpl.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/13/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincURLSessionNSURLSessionImpl.h"


@implementation ZincURLSessionNSURLSessionImpl

- (instancetype)init
{
    self = [super init];
    if (self) {
        _URLSession = [NSURLSession sharedSession];
    }
    return self;
}

- (id<ZincURLSessionTask>)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
    NSURLSessionTask* task = [self.URLSession dataTaskWithRequest:request completionHandler:completionHandler];
    [task resume];
    return task;
}

- (id<ZincURLSessionTask>)downloadTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler
{
    NSURLSessionTask* task = [self.URLSession downloadTaskWithRequest:request completionHandler:completionHandler];
    [task resume];
    return task;
}

@end


@implementation NSURLSessionTask (ZincURLSessionTask)

- (BOOL)isFinished
{
    return self.state == NSURLSessionTaskStateCompleted;
}

@end
