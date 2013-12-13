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

- (id<ZincURLSession>)getLegacyURLSessionImpl
{
    ZincURLSessionNSURLConnectionImpl* URLConnImpl = [[ZincURLSessionNSURLConnectionImpl alloc] initWithOperationQueue:self.networkOperationQueue];
    URLConnImpl.backgroundTaskDelegate = self.backgroundTaskDelegate;
    return URLConnImpl;
}

- (id<ZincURLSession>)getModernURLSessionImpl
{
#if defined(__IPHONE_7_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPShouldUsePipelining = YES;
    return [NSURLSession sessionWithConfiguration:config];
#else
    return nil;
#endif
}

- (id<ZincURLSession>)getURLSession
{
    id<ZincURLSession> URLSession = nil;

    if (!_NSURLSessionAvailable || self.wantLegacyImplementation) {
        URLSession = [self getLegacyURLSessionImpl];
    } else {
        URLSession = [self getModernURLSessionImpl];
    }

    return URLSession;
}

@end
