//
//  ZincProgress.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const long long ZincProgressNotYetDetermined;


typedef void (^ZincProgressBlock)(id source, long long currentProgress, long long totalProgress, float percent);


@protocol ZincProgress <NSObject>

@required

/**
 @discussion NOT Key-Value Observable
 */
- (long long) currentProgressValue;

/**
 @discussion NOT Key-Value Observable
 */
- (long long) maxProgressValue;

- (BOOL) isFinished;

@end


@protocol ZincObservableProgress <ZincProgress>

/**
 @discussion Is Key-Value Observable
 */
@property (nonatomic, assign, readonly) long long currentProgressValue;

/**
 @discussion Is Key-Value Observable
 */
@property (nonatomic, assign, readonly) long long maxProgressValue;

/**
 @discussion Is Key-Value Observable
 */
@property (nonatomic, assign, readonly) float progressPercentage;

@end


@interface ZincProgressItem : NSObject <ZincObservableProgress>

/**
 @discussion Is Key-Value Observable
 */
//@property (nonatomic, assign, readwrite) long long currentProgressValue;

/**
 @discussion Is Key-Value Observable
 */
//@property (nonatomic, assign, readwrite) long long maxProgressValue;

@end


/**
 Helper function to calculate floating-point progress. Basically just avoids divide by zero.
 
 @param progress Progress object
 @return Current progress as a floating point value betetween 0.0f and 1.0f.
 */
extern float ZincProgressPercentageCalculate(id<ZincProgress> progress);

extern id<ZincProgress> ZincAggregatedProgressCalculate(NSArray* items);
