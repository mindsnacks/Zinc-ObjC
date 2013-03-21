//
//  ZincInternalTask.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 3/16/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincTask.h"

@interface ZincInternalTask : ZincTask

/**
 @discussion By default, and internal task's action is the same as it's method
   (the class name).
 */
+ (NSString *)action;

@end
