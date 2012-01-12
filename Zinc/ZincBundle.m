//
//  ZCBundle.m
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincBundle.h"
#import "ZincBundle+Private.h"

@interface ZincBundle ()
@property (nonatomic, retain, readwrite) NSString* bundleId;
@property (nonatomic, assign, readwrite) ZincVersion version;
@end

@implementation ZincBundle

@synthesize bundleId = _bundleId;
@synthesize version = _version;

- (id) initWithBundleId:(NSString*)bundleId version:(ZincVersion)version
{
    self = [super init];
    if (self) {
        self.bundleId = bundleId;
        self.version = version;
    }
    return self;
}

- (void) dealloc 
{
    [super dealloc];
}

+ (NSString*) catalogIdFromBundleId:(NSString*)bundleId
{
    NSArray* comps = [bundleId componentsSeparatedByString:@"."];
    NSString* sourceId = [[comps subarrayWithRange:NSMakeRange(0, [comps count]-1)] componentsJoinedByString:@"."];
    return sourceId;
}

+ (NSString*) bundleNameFromBundleId:(NSString*)bundleId
{
    return [[bundleId componentsSeparatedByString:@"."] lastObject];
}

+ (NSString*) descriptorForBundleId:(NSString*)bundleId version:(ZincVersion)version
{
    return [NSString stringWithFormat:@"%@-%d", bundleId, version];
}

- (NSString*) descriptor
{
    return [[self class] descriptorForBundleId:self.bundleId version:self.version];
}


@end
