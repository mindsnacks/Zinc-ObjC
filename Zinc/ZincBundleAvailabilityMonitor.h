//
//  ZincBundleCloneMonitor.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepoMonitor.h"

@interface ZincBundleAvailabilityMonitor : ZincRepoMonitor

- (id)initWithRepo:(ZincRepo*)repo bundleIDs:(NSArray*)bundleIDs;


/**
 @discussion Is Key-Value Observable
 */
@property (nonatomic, readonly) float totalProgress;



@end
