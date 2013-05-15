//
//  ZincActivityMonitor.h
//  
//
//  Created by Andy Mroczkowski on 9/8/12.
//
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"
#import "ZincProgress.h"


@class ZincTask;
@class ZincActivityMonitor;


static NSTimeInterval const kZincActivityMonitorDefaultRefreshInterval = 0.5;
extern NSString* const ZincActivityMonitorRefreshedNotification;


@interface ZincActivityMonitor : NSObject

@property (nonatomic, assign) NSTimeInterval refreshInterval;

@property (nonatomic, copy) ZincProgressBlock progressBlock;

- (void) startMonitoring;
- (void) stopMonitoring;
@property (nonatomic, readonly, assign) BOOL isMonitoring;

- (NSArray*) items;

@end


@interface ZincActivityItem : NSObject <ZincObservableProgress>

@property (nonatomic, readonly, weak) ZincActivityMonitor* monitor;

@property (nonatomic, readonly, strong) ZincTask* task;

- (BOOL) isFinished;

#pragma mark ZincObservableProgress

@property (nonatomic, assign, readonly) float progress;
@property (nonatomic, assign, readonly) long long currentProgressValue;
@property (nonatomic, assign, readonly) long long maxProgressValue;

@end