//
//  ZincEventHelpers.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincEventHelpers.h"

#import "ZincHTTPRequestOperation.h"

@implementation ZincEventHelpers

+ (NSDictionary *)attributesForRequestOperation:(id<ZincHTTPRequestOperation>)op
{
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithCapacity:2];

    if (op.request != nil) {
        NSMutableDictionary* requestInfo = [NSMutableDictionary dictionary];
        info[@"URLRequest"] = requestInfo;
        requestInfo[@"URL"] = op.request.URL;
    }

    if (op.response != nil ) {
        NSMutableDictionary* responseInfo = [NSMutableDictionary dictionary];
        info[@"URLResponse"] = responseInfo;
        if ([op.response respondsToSelector:@selector(allHeaderFields)]) {
            responseInfo[@"Headers"] = [op.response performSelector:@selector(allHeaderFields)];
        }
    }

    return info;
}


@end
