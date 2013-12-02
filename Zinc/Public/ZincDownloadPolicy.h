//
//  ZincDownloadPolicy.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/14/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ZincConnectionTypeAny,
    ZincConnectionTypeWiFiOnly,
} ZincConnectionType;

extern NSString* const ZincDownloadPolicyPriorityChangeNotification;
extern NSString* const ZincDownloadPolicyPriorityChangeBundleIDKey;
extern NSString* const ZincDownloadPolicyPriorityChangePriorityKey;


#pragma mark -


@protocol ZincDownloadPolicyRule <NSObject>

- (BOOL) allowBundleWithID:(NSString*)bundleID priority:(NSOperationQueuePriority)priority;

@end


#pragma mark -


@interface ZincDownloadPolicy : NSObject

/**
 Returns a bundle policy with no rules for specific priorities and default
 required connection type ZincConnectionTypeAny.
 */
- (id) init;


#pragma mark Bundle Prioritization

- (NSOperationQueuePriority) priorityForBundleWithID:(NSString*)bundleID;

- (void) setPriority:(NSOperationQueuePriority)priority forBundleWithID:(NSString*)bundleID;


#pragma mark Connectivity Rules

@property (nonatomic, assign) ZincConnectionType defaultRequiredConnectionType;

- (ZincConnectionType) requiredConnectionTypeForPriority:(NSOperationQueuePriority)priority;

- (void) setRequiredConnectionType:(ZincConnectionType)connectionType forPrioritiesGreaterThanOrEqualToPriority:(NSOperationQueuePriority)priority;

- (void) removePriorityForConnectionType:(ZincConnectionType)connectionType;


#pragma mark Custom Rules

/**
 Add a custom rule.
 */
- (void) addRule:(id<ZincDownloadPolicyRule>)rule;

/**
 Remove a custom rule.
 */
- (void) removeRule:(id<ZincDownloadPolicyRule>)rule;


#pragma mark Convenience

/**
 Resets the policy to defaults, and if it was just created using init
 */
- (void) reset;

@end


#pragma mark -


typedef BOOL (^ZincDownloadPolicyBlockRuleHandler)(NSString* bundleID, NSOperationQueuePriority priority);

@interface ZincDownloadPolicyBlockRule : NSObject <ZincDownloadPolicyRule>

+ (instancetype) ruleWithBlock:(ZincDownloadPolicyBlockRuleHandler)block;

@end



