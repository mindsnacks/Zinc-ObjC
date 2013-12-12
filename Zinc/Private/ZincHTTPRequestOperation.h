//
//  ZincHTTPRequestOperation.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZincHTTPRequestOperation <NSObject>

@required
- (instancetype)initWithRequest:(NSURLRequest *)request;


- (void)setDownloadProgressBlock:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))block;


@property (readonly, nonatomic, strong) NSURLRequest *request;
@property (readonly, nonatomic, strong) NSHTTPURLResponse *response;

@property (nonatomic, strong) NSOutputStream *outputStream;

@property (readonly, nonatomic, strong) NSData *responseData;

@property (readonly, nonatomic, strong) NSError *error;


@property (nonatomic, readonly) BOOL hasAcceptableStatusCode;


- (void)waitUntilFinished;
- (BOOL)isFinished;


@end
