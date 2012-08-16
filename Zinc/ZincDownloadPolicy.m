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


@interface ZincDownloadPolicy ()
@property (nonatomic, retain) NSMutableDictionary* requiredConnectionTypeByPriority;
@property (nonatomic, retain) NSMutableDictionary* prioritiesByBundleId;
@end

@implementation ZincDownloadPolicy

- (id)init
{
    self = [super init];
    if (self) {
        _requiredConnectionTypeByPriority = [[NSMutableDictionary alloc] init];
        _prioritiesByBundleId = [[NSMutableDictionary alloc] init];
        _defaultRequiredConnectionType = ZincConnectionTypeAny;
    }
    return self;
}

- (void)dealloc
{
    [_requiredConnectionTypeByPriority release];
    [_prioritiesByBundleId release];
    [super dealloc];
}

- (NSOperationQueuePriority) priorityForBundleWithId:(NSString*)bundleId
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
    @synchronized(self.requiredConnectionTypeByPriority) {
        
        NSNumber *specificRequiredConnectionType = [self.requiredConnectionTypeByPriority objectForKey:
                                                    [NSNumber numberWithInteger:priority]];
        if (specificRequiredConnectionType != nil) {
            return [specificRequiredConnectionType integerValue];
        }
        
        return self.defaultRequiredConnectionType;
    }
}

- (void)setRequiredConnectionType:(ZincConnectionType)connectionType forPriority:(NSOperationQueuePriority)priority
{
    @synchronized(self.requiredConnectionTypeByPriority) {
        [self.requiredConnectionTypeByPriority setObject:[NSNumber numberWithInteger:connectionType]
                                                  forKey:[NSNumber numberWithInteger:priority]];
    }
}

- (void)removeConnectionTypeRequirementForPriority:(NSOperationQueuePriority)priority
{
    @synchronized(self.requiredConnectionTypeByPriority) {
        [self.requiredConnectionTypeByPriority removeObjectForKey:[NSNumber numberWithInteger:priority]];
    }
}


@end
