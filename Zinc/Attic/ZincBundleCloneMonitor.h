//
//  ZincTaskRef2.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/3/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincGlobals.h"

@class ZincRepo;

//
//enum {
//    
//    /* Whether the change dictionaries sent in notifications should contain NSKeyValueChangeNewKey and NSKeyValueChangeOldKey entries, respectively.
//     */
//    NSKeyValueObservingOptionNew = 0x01 << 0,
//    NSKeyValueObservingOptionOld = 0x02,
//}

static NSTimeInterval const kZincBundleCloneMonitorDefaultRefreshInterval = 0.5;

typedef void (^ZincBundleCloneMonitorProgressBlock)(long long currentProgress, long long totalProgress, float percent);


@interface ZincBundleCloneMonitor : NSObject

+ (ZincBundleCloneMonitor*)bundleCloneMonitorWithRepo:(ZincRepo*)repo
                                             bundleID:(NSString*)bundleId;

@property (nonatomic, readonly, retain) ZincRepo* repo;
@property (nonatomic, readonly, retain) NSString* bundleID;

@property (nonatomic, assign) NSTimeInterval refreshInterval;
@property (nonatomic, copy) ZincBundleCloneMonitorProgressBlock progressBlock;
@property (nonatomic, copy) ZincCompletionBlock completionBlock;

- (void) startMonitoring;
- (void) stopMonitoring;
@property (nonatomic, readonly, assign) BOOL isMonitoring;

/**
 @discussion Is Key-Value Observable
 */
@property (nonatomic, readonly) float progress;

/* all events including events from subtasks */
- (NSArray*) events;

/* all errors that occurred including errors from subtasks */
- (NSArray*) errors;

@end



