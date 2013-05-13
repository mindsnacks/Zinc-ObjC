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
@property (nonatomic, retain) NSMutableDictionary* prioritiesByBundleID;
@property (nonatomic, retain) NSMutableArray* rules;
@end

@implementation ZincDownloadPolicy

- (id)init
{
    self = [super init];
    if (self) {
        _prioritiesByRequiredConnectionType = [[NSMutableDictionary alloc] init];
        _prioritiesByBundleID = [[NSMutableDictionary alloc] init];
        _rules = [[NSMutableArray alloc] init];
        _defaultRequiredConnectionType = kInitialDefaultConnectionType;
    }
    return self;
}

- (void)dealloc
{
    [_prioritiesByRequiredConnectionType release];
    [_prioritiesByBundleID release];
    [_rules release];
    [super dealloc];
}

- (NSOperationQueuePriority) priorityForBundleWithID:(NSString*)bundleID
{
    @synchronized(self.prioritiesByBundleID)
    {
        NSNumber* prio = [self.prioritiesByBundleID objectForKey:bundleID];
        if (prio != nil) {
            return [prio integerValue];
        } else {
            return NSOperationQueuePriorityNormal;
        }
    }
}

- (void) setPriority:(NSOperationQueuePriority)priority forBundleWithID:(NSString*)bundleID
{
    @synchronized(self.prioritiesByBundleID)
    {
        [self.prioritiesByBundleID setObject:[NSNumber numberWithInteger:priority] forKey:bundleID];
    }
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              bundleID, ZincDownloadPolicyPriorityChangeBundleIDKey,
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

- (void)addRule:(id<ZincDownloadPolicyRule>)rule
{
    @synchronized(self.rules) {
        [self.rules addObject:rule];
    }
}

- (void)removeRule:(id<ZincDownloadPolicyRule>)rule
{
    @synchronized(self.rules) {
        [self.rules removeObject:rule];
    }
}

- (void) reset
{
    @synchronized(self.prioritiesByRequiredConnectionType) {
        [self.prioritiesByRequiredConnectionType removeAllObjects];
    }
    
    @synchronized(self.prioritiesByBundleID) {
        [self.prioritiesByBundleID removeAllObjects];
    }

    @synchronized(self.rules) {
        [self.rules removeAllObjects];
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

- (BOOL) doRulesAllowBundleID:(NSString*)bundleID
{
    @synchronized(self.rules) {
        for (id<ZincDownloadPolicyRule> rule in self.rules) {
            if (![rule allowBundleWithID:bundleID priority:[self priorityForBundleWithID:bundleID]]) {
                return NO;
            }
        }
    }
    return YES;
}

@end


@interface ZincDownloadPolicyBlockRule ()
@property (nonatomic, copy) ZincDownloadPolicyBlockRuleHandler block;
@end


@implementation ZincDownloadPolicyBlockRule

+ (instancetype)ruleWithBlock:(ZincDownloadPolicyBlockRuleHandler)block
{
    ZincDownloadPolicyBlockRule* r = [[[self alloc] init] autorelease];
    r.block = block;
    return r;
}

- (void)dealloc
{
    [_block release];
    [super dealloc];
}

- (BOOL) allowBundleWithID:(NSString*)bundleID priority:(NSOperationQueuePriority)priority
{
    return self.block(bundleID, priority);
}

@end
