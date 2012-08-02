//
//  ZincJSONSerialization.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/1/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincJSONSerialization.h"
#import "ZincKSJSON.h"

@implementation ZincJSONSerialization

static id _NSJSONSerialization = nil;

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"NSJSONSerialization");
        if (cls != nil) {
            _NSJSONSerialization = cls;
        }
    });
}

+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)error
{
    if (_NSJSONSerialization != nil) {
        return [_NSJSONSerialization JSONObjectWithData:data options:opt error:error];
    } else {
        NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        return [ZincKSJSON deserializeString:jsonString error:error];
    }
}

+ (NSData *)dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error
{
    if (_NSJSONSerialization != nil) {
        return [_NSJSONSerialization dataWithJSONObject:obj options:opt error:error];
    } else {
        NSString *jsonString = [ZincKSJSON serializeObject:obj error:error];
        return [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    }
}


@end
