//
//  ZincURLSessionNSURLSessionImpl.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/13/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincURLSessionNSURLSessionImpl.h"

@implementation  NSURLSession (ZincURLSession)

@end


@implementation NSURLSessionTask (ZincURLSessionTask)

- (BOOL)isFinished
{
    return self.state == NSURLSessionTaskStateCompleted;
}

@end
