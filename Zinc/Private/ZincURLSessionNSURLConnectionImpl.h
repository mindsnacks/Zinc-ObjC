//
//  ZincURLSessionImpl.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZincURLSession.h"

@protocol ZincURLSessionBackgroundTaskDelegate;
@class ZincHTTPURLConnectionOperation;

@interface ZincURLSessionNSURLConnectionImpl : NSObject <ZincURLSession>

- (instancetype)initWithOperationQueue:(NSOperationQueue *)opQueue;

@property (nonatomic, weak) id<ZincURLSessionBackgroundTaskDelegate> backgroundTaskDelegate;

- (id<ZincURLSessionTask>)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

- (id<ZincURLSessionTask>)downloadTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;

@end


@protocol ZincURLSessionBackgroundTaskDelegate <NSObject>

/**
 If not implemented, will default to YES
 */
- (BOOL)urlSession:(ZincURLSessionNSURLConnectionImpl *)urlSession shouldExecuteOperationsInBackground:(ZincHTTPURLConnectionOperation *)operation;

@end