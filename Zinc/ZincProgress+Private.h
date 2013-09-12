//
//  ZincProgressItem+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/9/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincProgress.h"

@interface ZincProgressItem ()

@property (nonatomic, assign, readwrite) long long currentProgressValue;
@property (nonatomic, assign, readwrite) long long maxProgressValue;
@property (nonatomic, assign, readwrite) float progressPercentage;

/**
 @return YES if progress is updated (different from last value), NO otherwise
 */
- (BOOL) updateCurrentProgressValue:(long long)currentProgressValue maxProgressValue:(long long)maxProgressValue;

- (BOOL) updateFromProgress:(id<ZincProgress>)progress;

- (void) finish;

@end