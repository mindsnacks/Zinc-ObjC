//
//  ZincURLSessionFactory.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/13/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincURLSessionFactory.h"
#import "ZincURLSessionNSURLConnectionImpl.h"
#import "ZincURLSessionNSURLSessionImpl.h"

@implementation ZincURLSessionFactory
{
    BOOL _NSURLSessionAvailable;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _NSURLSessionAvailable = NSClassFromString(@"NSURLSession") != nil;
    }
    return self;
}

- (id<ZincURLSession>)getURLSession
{
    id<ZincURLSession> URLSession = nil;

    if (!_NSURLSessionAvailable || self.wantLegacyImplementation) {

        ZincURLSessionNSURLConnectionImpl* URLConnImpl = [[ZincURLSessionNSURLConnectionImpl alloc] initWithOperationQueue:self.networkOperationQueue];
        URLConnImpl.backgroundTaskDelegate = self.backgroundTaskDelegate;
        URLSession = URLConnImpl;

    } else {

        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPShouldUsePipelining = YES;
        URLSession = [NSURLSession sessionWithConfiguration:config];
    }

    return URLSession;
}

@end
