//
//  ZincProgress.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^ZincProgressBlock)(id context, long long currentProgress, long long totalProgress, float percent);


@protocol ZincProgress <NSObject>

/**
 @discussion NOT Key-Value Observable
 */
- (long long) currentProgressValue;

/**
 @discussion NOT Key-Value Observable
 */
- (long long) maxProgressValue;

/**
 @discussion NOT Key-Value Observable
 */
- (float) progress;

@end



@protocol ZincObservableProgress <ZincProgress>

/**
 @discussion Is Key-Value Observable
 */
@property (atomic, assign, readonly) float progress;

/**
 @discussion Is Key-Value Observable
 */
@property (atomic, assign, readonly) long long currentProgressValue;

/**
 @discussion Is Key-Value Observable
 */
@property (atomic, assign, readonly) long long maxProgressValue;

@end


/**
 @discussion Helper function to calculate floating-point progress. Basically just avoids divide by zero.
 */
extern float ZincProgressCalculate(id<ZincProgress>);