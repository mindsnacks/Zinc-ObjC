//
//  ZincURLSessionNSURLSessionImpl.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/13/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincURLSession.h"

@interface ZincURLSessionNSURLSessionImpl : NSObject <ZincURLSession>

- (id<ZincURLSessionTask>)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

- (id<ZincURLSessionTask>)downloadTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;

@property (readonly, strong) NSURLSession* URLSession;

@end



@interface NSURLSessionTask (ZincURLSessionTask) <ZincURLSessionTask>

@end