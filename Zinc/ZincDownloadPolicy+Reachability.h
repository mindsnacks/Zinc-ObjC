//
//  ZincDownloadPolicy+Reachability.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/15/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadPolicy.h"

@interface ZincDownloadPolicy (Reachability)

- (BOOL) shouldDownloadBundleWithPriority:(NSOperationQueuePriority)priority;

@end
