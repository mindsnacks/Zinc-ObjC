//
//  ZincURLSessionNSURLSessionImpl.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/13/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincURLSessionNSURLSessionImpl.h"


#if defined(__IPHONE_7_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0

@implementation  NSURLSession (ZincURLSession)

@end


@implementation NSURLSessionTask (ZincURLSessionTask)

- (BOOL)isFinished
{
    return self.state == NSURLSessionTaskStateCompleted;
}

@end

#endif
