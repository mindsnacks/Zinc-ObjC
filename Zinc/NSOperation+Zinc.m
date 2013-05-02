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
    NSMutableArray *pendingOperationsToVisit = [NSMutableArray arrayWithObject:self];
    NSMutableSet *visitedOperations = [NSMutableSet set];
    NSMutableSet *allDependencies = [NSMutableSet set];

    while ([pendingOperationsToVisit count] > 0) {

        // mark the operation as "visited"
        NSOperation *op = [pendingOperationsToVisit lastObject];
        [pendingOperationsToVisit removeLastObject];
        [visitedOperations addObject:op];

        // loop through all dependencies, but only recusively visit those
        // we haven't already visited
        NSArray* deps = [op dependencies];
        for (id obj in deps) {
            [allDependencies addObject:obj];
            if (![visitedOperations containsObject:obj]) {
                [pendingOperationsToVisit addObject:obj];
            }
        }
    }
    
    return [allDependencies allObjects];
}

@end

