//
//  ZincURLSession.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol ZincURLSessionTask <NSObject>

#pragma - mark NSURLSessionTask-ish

@property (readonly, copy) NSURLRequest *originalRequest;
@property (readonly, copy) NSURLRequest *currentRequest;    /* may differ from originalRequest due to http server redirection */
@property (readonly, copy) NSURLResponse *response;	    /* may be nil if no response has been received */

/* Byte count properties may be zero if no body is expected,
 * or NSURLSessionTransferSizeUnknown if it is not possible
 * to know how many bytes will be transferred.
 */

/* number of body bytes already received */
@property (readonly) int64_t countOfBytesReceived;

/* number of byte bytes we expect to receive, usually derived from the Content-Length header of an HTTP response. */
@property (readonly) int64_t countOfBytesExpectedToReceive;

/*
 * The error, if any, delivered via -URLSession:task:didCompleteWithError:
 * This property will be nil in the event that no error occured.
 */
@property (readonly, copy) NSError *error;


#pragma - NSOperation-ish

- (BOOL)isFinished;

@end


@protocol ZincURLSession <NSObject>

- (id<ZincURLSessionTask>)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

- (id<ZincURLSessionTask>)downloadTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;

@end
