//
//  ZincMaintenanceTask.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/18/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincTask.h"

@interface ZincMaintenanceTask : ZincTask

+ (ZincTaskDescriptor*) taskDescriptorForResource:(NSURL*)resource;

#pragma mark Private

- (void) doMaintenance;

@end
