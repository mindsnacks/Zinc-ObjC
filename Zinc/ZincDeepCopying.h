//
//  NSDictionary+ZincDeepCopying.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/22/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * Deep copying utility methods.
 *
 * These ONLY deep copy container classes (dict, array, set) and
 * not any content objects.
 *
 * These methods return AUTORELEASED objects.
 */

@interface NSDictionary (ZincDeepCopying)

- (NSDictionary*) zinc_deepCopy;
- (NSMutableDictionary*) zinc_deepMutableCopy;

@end


@interface NSArray (ZincDeepCopying)

- (NSArray*) zinc_deepCopy;
- (NSMutableArray*) zinc_deepMutableCopy;

@end


@interface NSSet (ZincDeepCopying)

- (NSSet*) zinc_deepCopy;
- (NSMutableSet*) zinc_deepMutableCopy;

@end