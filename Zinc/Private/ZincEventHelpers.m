//
//  ZincEventHelpers.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincEventHelpers.h"

@implementation ZincEventHelpers

+ (NSDictionary *)attributesForRequest:(NSURLRequest *)request andResponse:(NSURLResponse *)response
{
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithCapacity:2];

    if (request != nil) {
        NSMutableDictionary* requestInfo = [NSMutableDictionary dictionary];
        info[@"URLRequest"] = requestInfo;
        requestInfo[@"URL"] = request.URL;
    }

    if (response != nil ) {
        NSMutableDictionary* responseInfo = [NSMutableDictionary dictionary];
        info[@"URLResponse"] = responseInfo;
        if ([response respondsToSelector:@selector(allHeaderFields)]) {
            responseInfo[@"Headers"] = [response performSelector:@selector(allHeaderFields)];
        }
    }

    return info;
    
}

@end
