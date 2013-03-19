//
//  ZincHTTPRequestOperation+ZincErrorContext.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 3/18/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincHTTPRequestOperation+ZincContextInfo.h"

@implementation ZincHTTPRequestOperation (ZincContextInfo)

- (NSDictionary*) zinc_contextInfo
{
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithCapacity:2];

    if (self.request != nil) {
        NSMutableDictionary* requestInfo = [NSMutableDictionary dictionary];
        [info setObject:requestInfo forKey:@"URLRequest"];
        [requestInfo setObject:self.request.URL forKey:@"URL"];
    }
    
    if (self.response != nil ) {
        NSMutableDictionary* responseInfo = [NSMutableDictionary dictionary];
        [info setObject:responseInfo forKey:@"URLResponse"];
        [responseInfo setObject:[self.response allHeaderFields] forKey:@"Headers"];
    }
    
    return info;
}

@end
