//
//  NSDictionary+ZincDeepCopying.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/22/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDeepCopying.h"

@implementation NSDictionary (ZincDeepCopying)

- (NSDictionary*) zinc_deepCopy
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id val = obj;
        if ([obj respondsToSelector:@selector(zinc_deepCopy)]) {
            val = [obj zinc_deepCopy];
        }
        [dict setObject:val forKey:key];
    }];
    return [NSDictionary dictionaryWithDictionary:dict];
}

- (NSMutableDictionary*) zinc_deepMutableCopy
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id val = obj;
        if ([obj respondsToSelector:@selector(zinc_deepMutableCopy)]) {
            val = [obj zinc_deepMutableCopy];
        }
        [dict setObject:val forKey:key];
    }];
    return dict;
}

@end


@implementation NSArray (ZincDeepCopying)

- (NSArray*) zinc_deepCopy
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:[self count]];
    for (id obj in self) {
        id val = obj;
        if ([val respondsToSelector:@selector(zinc_deepCopy)]) {
            val = [obj zinc_deepCopy];
        }
        [array addObject:val];
    }
    return [NSArray arrayWithArray:array];
}

- (NSMutableArray*) zinc_deepMutableCopy
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:[self count]];
    for (id obj in self) {
        id val = obj;
        if ([val respondsToSelector:@selector(zinc_deepMutableCopy)]) {
            val = [obj zinc_deepMutableCopy];
        }
        [array addObject:val];
    }
    return array;
}

@end


@implementation NSSet (ZincDeepCopying)

- (NSArray*) zinc_deepCopy
{
    NSMutableSet* set = [NSMutableSet setWithCapacity:[self count]];
    for (id obj in self) {
        id val = obj;
        if ([val respondsToSelector:@selector(zinc_deepCopy)]) {
            val = [obj zinc_deepCopy];
        }
        [set addObject:val];
    }
    return [NSSet setWithSet:set];
}

- (NSMutableSet*) zinc_deepMutableCopy
{
    NSMutableSet* set = [NSMutableSet setWithCapacity:[self count]];
    for (id obj in self) {
        id val = obj;
        if ([val respondsToSelector:@selector(zinc_deepMutableCopy)]) {
            val = [obj zinc_deepMutableCopy];
        }
        [set addObject:val];
    }
    return set;
}

@end