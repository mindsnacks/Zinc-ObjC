//
//  ZincJSONSerialization.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/1/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincJSONSerialization.h"

@implementation ZincJSONSerialization

+ (id)JSONObjectWithData:(NSData *)data options:(ZincJSONReadingOptions)opt error:(NSError **)outError
{
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:opt error:&error];

    if (error && outError) {
        // Add the original JSON string to the user info
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        NSString *JSONString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        userInfo[@"zinc_JSONString"] = JSONString ?: @"<nil>";

        error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
        *outError = error;
    }

    return object;
}

+ (NSData *)dataWithJSONObject:(id)obj options:(ZincJSONReadingOptions)opt error:(NSError **)error
{
    return [NSJSONSerialization dataWithJSONObject:obj options:opt error:error];
}


@end
