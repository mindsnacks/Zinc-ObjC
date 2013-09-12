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


/**
 `ZincActivityMonitor`

 This class is part of the *Zinc Public API*.

 */
@interface ZincActivityMonitor : NSObject

@property (nonatomic, assign) NSTimeInterval refreshInterval;

@property (nonatomic, copy) ZincProgressBlock progressBlock;

- (void) startMonitoring;
- (void) stopMonitoring;
@property (nonatomic, readonly, assign) BOOL isMonitoring;

- (NSArray*) items;

@end


/**
 `ZincActivityItem`

 This class is part of the *Zinc Public API*.

 */
@interface ZincActivityItem : ZincProgressItem

@property (nonatomic, readonly, weak) ZincActivityMonitor* monitor;

@property (nonatomic, readonly, strong) ZincOperation* operation;

@end


///----------------
/// @name Constants
///----------------

/**
 Default auto refresh interval
 */
static NSTimeInterval const kZincActivityMonitorDefaultRefreshInterval = 0.5;

/**
 Notification that is posted when ActivityMonitor refreshes
 */
extern NSString* const ZincActivityMonitorRefreshedNotification;


