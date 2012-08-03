//
//  ZincOperation.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

// this is the same as NSOperation default
const double kZincOperationInitialDefaultThreadPriority = 0.5;

@interface ZincOperation : NSOperation

+ (void)setDefaultThreadPriority:(double)defaultThreadPriority;
+ (double)defaultThreadPriority;

- (NSInteger) currentProgressValue;
- (NSInteger) maxProgressValue;

- (double) progress;

@end
