//
//  ZincDownloadPolicy.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/14/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    ZincConnectionTypeAny,
    ZincConnectionTypeWiFiOnly,
};
typedef NSInteger ZincConnectionType;


@interface ZincDownloadPolicy : NSObject

/**
 @discussion Returns a bundle policy with no rules for specific priorities
 and default required connection type ZincConnectionTypeAny 
 */
- (id) init;

@property (nonatomic, assign) ZincConnectionType* defaultRequiredConnectionType;

- (ZincConnectionType)requiredConnectionTypeForBundlePriority:(NSOperationQueuePriority)priority;
- (void)setRequiredConnectionType:(ZincConnectionType)connectionType forBundlePriority:(NSOperationQueuePriority)priority;

@end
