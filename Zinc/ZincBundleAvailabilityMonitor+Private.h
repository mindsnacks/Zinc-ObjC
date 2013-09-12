//
//  ZincBundleAvailabilityMonitor+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/10/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincBundleAvailabilityMonitor.h"


@interface ZincBundleAvailabilityMonitorActivityItem ()

/**
 Designated initializer
 */
- (id) initWithMonitor:(ZincBundleAvailabilityMonitor*)monitor request:(ZincBundleAvailabilityRequirement*)request;

@end