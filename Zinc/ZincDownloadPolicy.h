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

extern NSString* const ZincDownloadPolicyPriorityChangeNotification;
extern NSString* const ZincDownloadPolicyPriorityChangeBundleIDKey;
extern NSString* const ZincDownloadPolicyPriorityChangePriorityKey;

@interface ZincDownloadPolicy : NSObject

/**
 @discussion Returns a bundle policy with no rules for specific priorities
 and default required connection type ZincConnectionTypeAny 
 */
- (id) init;

#pragma mark Bundle Prioritization

- (NSOperationQueuePriority) priorityForBundleWithID:(NSString*)bundleId;

- (void) setPriority:(NSOperationQueuePriority)priority forBundleWithId:(NSString*)bundleId;

#pragma mark Connectivity Rules

@property (nonatomic, assign) ZincConnectionType defaultRequiredConnectionType;

- (ZincConnectionType)requiredConnectionTypeForPriority:(NSOperationQueuePriority)priority;

- (void)setRequiredConnectionType:(ZincConnectionType)connectionType forPriority:(NSOperationQueuePriority)priority;

- (void)removeConnectionTypeRequirementForPriority:(NSOperationQueuePriority)priority;

#pragma mark Convenience

- (ZincConnectionType) requiredConnectionTypeForBundleID:(NSString*)bundleID;

@end
