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

@class ZincRepo;

@interface ZincOperation : NSOperation <ZincProgress>

- (id)initWithRepo:(ZincRepo*)repo;
@property (nonatomic, assign, readonly) ZincRepo* repo;


#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (void)setShouldExecuteAsBackgroundTask;
#endif


+ (void) setDefaultThreadPriority:(double)defaultThreadPriority;
+ (double) defaultThreadPriority;



@end
