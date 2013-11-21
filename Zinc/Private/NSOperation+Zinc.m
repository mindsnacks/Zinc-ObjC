//
//  NSOperation+Zinc.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 3/28/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "NSOperation+Zinc.h"
#import "ZincChildren.h"

@implementation NSOperation (Zinc)

- (NSSet*) zinc_allDependenciesIncludingChildren:(BOOL)includeChildren
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
        for (id dep in deps) {
            [allDependencies addObject:dep];
            if (includeChildren && [dep conformsToProtocol:@protocol(ZincChildren)]) {
                [allDependencies addObjectsFromArray:[(id<ZincChildren>)dep allChildren]];
            }
            if (![visitedOperations containsObject:dep]) {
                [pendingOperationsToVisit addObject:dep];
            }
        }
    }
    
    return allDependencies;
}

- (NSSet*) zinc_allDependencies
{
    return [self zinc_allDependenciesIncludingChildren:NO];
}

- (NSString*) zinc_dependencyGraph
{
    /*
     digraph graphname {
     a -> b -> c;
     b -> d;
     }
     */

    NSMutableArray *pendingOperationsToVisit = [NSMutableArray arrayWithObject:self];
    NSMutableSet *visitedOperations = [NSMutableSet set];
//    NSMutableString* dot = [NSMutableString stringWithFormat:@"digraph deps {\n"];

    NSMutableArray* nodes = [NSMutableArray array];
    NSMutableArray* edges = [NSMutableArray array];

    while ([pendingOperationsToVisit count] > 0) {

        // mark the operation as "visited"
        NSOperation *op = [pendingOperationsToVisit lastObject];
        [pendingOperationsToVisit removeLastObject];
        [visitedOperations addObject:op];

        [nodes addObject:
         [NSString stringWithFormat:@"op_%p [color=%@, style=%@];\n",
          op,
          [op isReady] ? @"green" : @"red",
          [op isFinished] ? @"dotted" : @"solid"]];

        NSMutableArray *list = [[op dependencies] mutableCopy];
        if ([op conformsToProtocol:@protocol(ZincChildren)]) {
            [list addObjectsFromArray:[(id<ZincChildren>)op immediateChildren]];
        }

        // loop through all dependencies, but only recusively visit those
        // we haven't already visited
        for (id dep in list) {

//            if ([dep isFinished]) continue;

            [edges addObject:
             [NSString stringWithFormat:@"op_%p -> op_%p;\n", op, dep]];

            if (![visitedOperations containsObject:dep]) {
                [pendingOperationsToVisit addObject:dep];
            }
        }
    }

    NSString* nodeString = [nodes componentsJoinedByString:@"\n"];
    NSString* edgeString = [edges componentsJoinedByString:@"\n"];



    return [NSString stringWithFormat:@"digraph deps {\n%@%@}",
            nodeString, edgeString];

}

@end

