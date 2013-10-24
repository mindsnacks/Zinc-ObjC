//
//  NSOperation+Zinc.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 3/28/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOperation (Zinc)

/**
 @param includeChildren should try to include children by checking if operations conform to the `ZincChildren` protocol
 @return recursively generate *all* dependencies of the operation
 */
- (NSSet*) zinc_allDependenciesIncludingChildren:(BOOL)includeChildren;

/**
 @return recursively generate *all* dependencies of the operation. Does not include children.
 */
- (NSSet*) zinc_allDependencies;

@end

