//
//  ZincOperation.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincChildren.h"


@protocol ZincProgress;


/**
 `ZincOperation`
 
 This class is part of the *Zinc Public API*.

 Base `NSOperation` class for all internal Zinc operations
 */
@interface ZincOperation : NSOperation <ZincChildren>

/**
 Set the initial thread priority for all Zinc operations. Defaults to `kZincOperationInitialDefaultThreadPriority`
 */
+ (void) setDefaultThreadPriority:(double)defaultThreadPriority;

/**
 Get the initial thread priority
 */
+ (double) defaultThreadPriority;

- (id<ZincProgress>)progress;

@end


#pragma mark -

/**
 0.5 - the same as NSOperation default
 */
extern double const kZincOperationInitialDefaultThreadPriority;

/**
 5.0 seconds
 */
extern double const kZincOperationReadinessUpdateInterval;


