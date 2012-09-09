//
//  ZincProgress.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZincProgress <NSObject>

/**
 @discussion NOT Key-Value observable
 */
- (long long) currentProgressValue;

/**
 @discussion NOT Key-Value observable
 */
- (long long) maxProgressValue;

/**
 @discussion NOT Key-Value observable
 */
- (double) progress;

@end



@protocol ZincObservableProgress <ZincProgress>

/**
 @discussion Is Key-Value Observable
 */
@property (nonatomic, readonly) float progress;

/**
 @discussion Is Key-Value Observable
 */
@property (atomic, assign) long long currentProgressValue;

/**
 @discussion Is Key-Value Observable
 */
@property (atomic, assign) long long maxProgressValue;

@end
