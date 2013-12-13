//
//  ZincURLSessionImpl.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZincURLSession.h"

@interface ZincURLSession : NSObject <ZincURLSession>

- (instancetype)initWithOperationQueue:(NSOperationQueue *)opQueue;

- (id<ZincURLSessionTask>)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

@end
