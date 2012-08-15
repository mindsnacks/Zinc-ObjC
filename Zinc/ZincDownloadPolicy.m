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

- (ZincConnectionType)requiredConnectionTypeForBundlePriority:(NSOperationQueuePriority)priority
{
    return [[self.requiredConnectionTypeByPriority objectForKey:
             [NSNumber numberWithInteger:priority]]
            integerValue];
}

- (void)setRequiredConnectionType:(ZincConnectionType)connectionType forBundlePriority:(NSOperationQueuePriority)priority
{
    [self.requiredConnectionTypeByPriority setObject:[NSNumber numberWithInteger:connectionType]
                                              forKey:[NSNumber numberWithInteger:priority]];
}

@end
