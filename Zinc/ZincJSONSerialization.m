//
//  ZincJSONSerialization.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/1/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincJSONSerialization.h"

@implementation ZincJSONSerialization

+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)error
{
    return [NSJSONSerialization JSONObjectWithData:data options:opt error:error];
}

+ (NSData *)dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error
{
    return [NSJSONSerialization dataWithJSONObject:obj options:opt error:error];
}


@end
