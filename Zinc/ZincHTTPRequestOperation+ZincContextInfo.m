//
//  ZincHTTPRequestOperation+ZincErrorContext.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 3/18/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincHTTPRequestOperation+ZincContextInfo.h"

@implementation AFHTTPRequestOperation (ZincContextInfo)

- (NSDictionary*) zinc_contextInfo
{
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithCapacity:2];

    if (self.request != nil) {
        NSMutableDictionary* requestInfo = [NSMutableDictionary dictionary];
        info[@"URLRequest"] = requestInfo;
        requestInfo[@"URL"] = self.request.URL;
    }
    
    if (self.response != nil ) {
        NSMutableDictionary* responseInfo = [NSMutableDictionary dictionary];
        info[@"URLResponse"] = responseInfo;
        responseInfo[@"Headers"] = [self.response allHeaderFields];
    }
    
    return info;
}

@end
