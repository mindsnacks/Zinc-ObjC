//
//  ZincActivityMonitor+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//


#import "ZincActivityMonitor.h"

@interface ZincActivityMonitor ()

- (void) update;

- (void) monitoringDidStart;
- (void) monitoringDidStop;

@end