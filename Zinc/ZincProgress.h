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
- (float) progressPercentage;

@end


@protocol ZincObservableProgress <ZincProgress>

/**
 @discussion Is Key-Value Observable
 */
@property (nonatomic, assign, readonly) float progressPercentage;

/**
 @discussion Is Key-Value Observable
 */
@property (nonatomic, assign, readonly) long long currentProgressValue;

/**
 @discussion Is Key-Value Observable
 */
@property (nonatomic, assign, readonly) long long maxProgressValue;

@end


@interface ZincProgressItem : NSObject <ZincObservableProgress>

- (BOOL) isFinished;

@end


/**
 Helper function to calculate floating-point progress. Basically just avoids divide by zero.
 
 @param progress Progress object
 @return Current progress as a floating point value betetween 0.0f and 1.0f.
 */
extern float ZincProgressPercentageCalculate(id<ZincProgress> progress);