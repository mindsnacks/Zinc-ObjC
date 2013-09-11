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


@class ZincOperation;


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


@interface ZincActivityItem : ZincProgressItem

@property (nonatomic, readonly, weak) ZincActivityMonitor* monitor;

@property (nonatomic, readonly, strong) ZincOperation* operation;

@end