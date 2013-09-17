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
 @discussion returns ALL dependencies of the operation, recursively.
 */
- (NSSet*) zinc_allDependencies;

@end

