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
 
 ## Usage Notes

 - `startMonitoring` must be called to start the monitor
 */
@interface ZincActivityMonitor : NSObject

///-----------------
/// @name Monitoring
//------------------

/**
 @param refreshInterval set the auto refresh interval. Set to `0` to disable  auto refresh
 */
@property (nonatomic, assign) NSTimeInterval refreshInterval;

/**
 Start monitoring
 */
- (void) startMonitoring;

/**
 Start monitoring
 */
- (void) stopMonitoring;

/**
 @return `YES` if current monitoring, `NO` otherwise
 */
@property (nonatomic, readonly, assign) BOOL isMonitoring;

///---------------
/// @name Progress
//----------------

/**
 Set a block to be called when progress has been updated. The block will be
 call for each individual item *and* for overall progress. For each individual
 item, the `source` parameter of the block will be the `ZincActivityItem`
 object. For overall progress, the `source` parameter will be the
 `ZincActivityMonitor`.
 */
@property (nonatomic, copy) ZincProgressBlock progressBlock;

/**
 @return an array of all `ZincActivityItem` objects this monitor owns
 */
- (NSArray*) items;

@end



/**
 `ZincAcitivySubject
 */
@protocol ZincActivitySubject <NSObject>

@required

- (id<ZincProgress>)progress;

- (BOOL) isFinished;

@end


/**
 `ZincActivityItem`

 This class is part of the *Zinc Public API*.

 */
@interface ZincActivityItem : ZincProgressItem

/**
 Reference to owning `ZincActivityMonitor`
 */
@property (nonatomic, readonly, weak) ZincActivityMonitor* monitor;

/**
 The subject of this item. May be nil.
 */
@property (nonatomic, readonly, strong) id<ZincActivitySubject> subject;

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


