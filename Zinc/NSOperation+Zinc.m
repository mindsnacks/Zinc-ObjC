//
//  NSOperation+Zinc.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 3/28/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "NSOperation+Zinc.h"

@implementation NSOperation (Zinc)

- (NSArray*) zinc_allDependencies
{
    NSMutableArray *todo = [NSMutableArray arrayWithObject:self];
    NSMutableSet *done = [NSMutableSet set];
    NSMutableArray *allDeps = [NSMutableArray array];

    while ([todo count] > 0) {

        NSOperation *op = [todo lastObject];
        [todo removeLastObject];
        [done addObject:op];

        NSArray* deps = [op dependencies];
        for (id obj in deps) {
            [allDeps addObject:obj];
            if (![done containsObject:obj]) {
                [todo addObject:obj];
            }
        }
    }
    
    return allDeps;
}

@end

