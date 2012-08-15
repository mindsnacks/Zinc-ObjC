//
//  ZincDownloadPolicy.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/14/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadPolicy.h"

@interface ZincDownloadPolicy ()
@property (nonatomic, retain) NSMutableDictionary* requiredConnectionTypeByPriority;
@end

@implementation ZincDownloadPolicy

- (id)init
{
    self = [super init];
    if (self) {
        _requiredConnectionTypeByPriority = [[NSMutableDictionary alloc] init];
        _defaultRequiredConnectionType = ZincConnectionTypeAny;
    }
    return self;
}

- (void)dealloc
{
    [_requiredConnectionTypeByPriority release];
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

- (void) setPriority:(NSOperationQueuePriority)priority forBundleWithId:(NSString*)bundleId;


- (ZincConnectionType)requiredConnectionTypeForBundlePriority:(NSOperationQueuePriority)priority
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

- (void)setRequiredConnectionType:(ZincConnectionType)connectionType forBundlePriority:(NSOperationQueuePriority)priority
{
    @synchronized(self.requiredConnectionTypeByPriority) {
        [self.requiredConnectionTypeByPriority setObject:[NSNumber numberWithInteger:connectionType]
                                                  forKey:[NSNumber numberWithInteger:priority]];
    }
}

@end
