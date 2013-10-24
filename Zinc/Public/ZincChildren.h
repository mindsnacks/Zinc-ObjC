//
//  ZincChildren.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/17/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol ZincChildren <NSObject>

/**
 @return all children that were directly added
 */
- (NSArray*) immediateChildren;

/**
 @return all children, including children's children
 */
- (NSArray*) allChildren;

@end

