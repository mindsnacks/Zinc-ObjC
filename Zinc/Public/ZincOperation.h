//
//  ZincOperation.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincProgress.h"

// 0.5 - the same as NSOperation default
extern double const kZincOperationInitialDefaultThreadPriority;

@interface ZincOperation : NSOperation <ZincProgress>

+ (void) setDefaultThreadPriority:(double)defaultThreadPriority;
+ (double) defaultThreadPriority;

@end
