//
//  ZincActivityMonitor.h
//  
//
//  Created by Andy Mroczkowski on 9/8/12.
//
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"

@class ZincTask;

static NSTimeInterval const kZincActivityMonitorDefaultRefreshInterval = 0.5;

@interface ZincActivityMonitor : NSObject

@property (nonatomic, assign) NSTimeInterval refreshInterval;

- (void) startMonitoring;
- (void) stopMonitoring;
@property (nonatomic, readonly, assign) BOOL isMonitoring;

@end


@interface ZincActivityItem : NSObject

@property (nonatomic, readonly) ZincTask* task;

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