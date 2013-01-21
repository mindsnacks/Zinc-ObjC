//
//  ZincDownloadPolicy.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/14/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadPolicy.h"

NSString* const ZincDownloadPolicyPriorityChangeNotification = @"ZincDownloadPolicyPriorityChangeNotification";
NSString* const ZincDownloadPolicyPriorityChangeBundleIDKey = @"bundleID";
NSString* const ZincDownloadPolicyPriorityChangePriorityKey = @"priority";

#define kInitialDefaultConnectionType ZincConnectionTypeAny

@interface ZincDownloadPolicy ()
@property (nonatomic, retain) NSMutableDictionary* prioritiesByRequiredConnectionType;
@property (nonatomic, retain) NSMutableDictionary* prioritiesByBundleId;
@end

@implementation ZincDownloadPolicy

- (id)init
{
    self = [super init];
    if (self) {
        _prioritiesByRequiredConnectionType = [[NSMutableDictionary alloc] init];
        _prioritiesByBundleId = [[NSMutableDictionary alloc] init];
        _defaultRequiredConnectionType = kInitialDefaultConnectionType;
    }
    return self;
}

- (void)dealloc
{
    [_prioritiesByRequiredConnectionType release];
    [_prioritiesByBundleId release];
    [super dealloc];
}

- (NSOperationQueuePriority) priorityForBundleWithID:(NSString*)bundleId
{
    @synchronized(self.prioritiesByBundleId)
    {
        NSNumber* prio = [self.prioritiesByBundleId objectForKey:bundleId];
        if (prio != nil) {
            return [prio integerValue];
        } else {
            return NSOperationQueuePriorityNormal;
        }
    }
}

- (void) setPriority:(NSOperationQueuePriority)priority forBundleWithId:(NSString*)bundleId
{
    @synchronized(self.prioritiesByBundleId)
    {
        [self.prioritiesByBundleId setObject:[NSNumber numberWithInteger:priority] forKey:bundleId];
    }
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              bundleId, ZincDownloadPolicyPriorityChangeBundleIDKey,
                              [NSNumber numberWithInteger:priority], ZincDownloadPolicyPriorityChangePriorityKey,
                              nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ZincDownloadPolicyPriorityChangeNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (ZincConnectionType)requiredConnectionTypeForPriority:(NSOperationQueuePriority)priority
{
    @synchronized(self.prioritiesByRequiredConnectionType) {
        
        NSArray* connectionTypes = [self.prioritiesByRequiredConnectionType allKeys];
        for (NSNumber* connectionType in connectionTypes) {
            NSNumber* registeredPriority = self.prioritiesByRequiredConnectionType[connectionType];
            if (priority >= [registeredPriority integerValue]) {
                return [connectionType integerValue];
            }
        }
        return self.defaultRequiredConnectionType;
    }
}

- (void)setRequiredConnectionType:(ZincConnectionType)connectionType forPrioritiesGreaterThanOrEqualToPriority:(NSOperationQueuePriority)priority
{
    @synchronized(self.prioritiesByRequiredConnectionType) {
        [self.prioritiesByRequiredConnectionType setObject:[NSNumber numberWithInteger:priority]
                                                    forKey:[NSNumber numberWithInteger:connectionType]];
    }
}

- (void)removePriorityForConnectionType:(ZincConnectionType)connectionType
{
    @synchronized(self.prioritiesByRequiredConnectionType) {
        [self.prioritiesByRequiredConnectionType removeObjectForKey:[NSNumber numberWithInteger:connectionType]];
    }
}

- (void) reset
{
    @synchronized(self.prioritiesByRequiredConnectionType) {
        [self.prioritiesByRequiredConnectionType removeAllObjects];
    }
    
    @synchronized(self.prioritiesByBundleId) {
        [self.prioritiesByBundleId removeAllObjects];
    }
    
    self.defaultRequiredConnectionType = kInitialDefaultConnectionType;
}

- (ZincConnectionType) requiredConnectionTypeForBundleID:(NSString*)bundleID
{
    @synchronized(self)
    {
        NSOperationQueuePriority priority = [self priorityForBundleWithID:bundleID];
        return [self requiredConnectionTypeForPriority:priority];
    }
}


@end
