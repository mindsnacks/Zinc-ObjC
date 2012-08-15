//
//  ZincDownloadPolicy+Reachability.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/15/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadPolicy+Reachability.h"
#import "Reachability.h"

@implementation ZincDownloadPolicy (Reachability)

- (BOOL) shouldDownloadBundleWithPriority:(NSOperationQueuePriority)priority
{
    ZincConnectionType requiredConnectionType = [self requiredConnectionTypeForBundlePriority:priority];
    if (requiredConnectionType == ZincConnectionTypeAny) {
        return YES;
    } else if (requiredConnectionType == ZincConnectionTypeWiFiOnly) {
        
        return [Reachability ]
        
    }
}

@end
