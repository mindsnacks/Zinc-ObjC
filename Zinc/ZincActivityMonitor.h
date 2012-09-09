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

static NSTimeInterval const kZincActivityMonitorDefaultRefreshInterval = 0.5;

@interface ZincActivityMonitor : NSObject

@property (nonatomic, assign) NSTimeInterval refreshInterval;

- (void) startMonitoring;
- (void) stopMonitoring;
@property (nonatomic, readonly, assign) BOOL isMonitoring;

@property (nonatomic, retain, readonly) NSArray* activityItems;

@end



// TODO: this is similar to ZincTaskRef!

@interface ZincActivityItem : NSObject <ZincObservableProgress>

@property (nonatomic, readonly) ZincTask* task;

@end