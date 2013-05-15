//
//  ZincTrackingRef.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#define kCodingKey_Distribution @"distribution"
#define kCodingKey_Version @"version"
#define kCodingKey_UpdateAutomatically @"auto_update"
#define kCodingKey_Flavor @"flavor"

#import "ZincTrackingInfo.h"

@implementation ZincTrackingInfo

@synthesize distribution = _distribution;
@synthesize version = _version;
@synthesize updateAutomatically = _updateAutomatically;
@synthesize flavor = _flavor;

+ (ZincTrackingInfo*) trackingInfoWithDistribution:(NSString*)distribution
                             updateAutomatically:(BOOL)updateAutomatically
{
    ZincTrackingInfo* info = [[ZincTrackingInfo alloc] init];
    info.distribution = distribution;
    info.version = ZincVersionInvalid;
    info.updateAutomatically = updateAutomatically;
    return info;
}

+ (ZincTrackingInfo*) trackingInfoWithDistribution:(NSString*)distribution
                                         version:(ZincVersion)version
{
    ZincTrackingInfo* info = [[ZincTrackingInfo alloc] init];
    info.distribution = distribution;
    info.version = version;
    info.updateAutomatically = NO;
    return info;
}

+ (ZincTrackingInfo*) trackingInfoFromDictionary:(NSDictionary*)dict
{
    if (dict == nil) return nil;
    
    ZincTrackingInfo* info = [[ZincTrackingInfo alloc] init];
    info.distribution = dict[kCodingKey_Distribution];
    info.version = [dict[kCodingKey_Version] integerValue];
    info.updateAutomatically = [dict[kCodingKey_UpdateAutomatically] boolValue];
    info.flavor = dict[kCodingKey_Flavor];
    return info;
}

- (id)init
{
    self = [super init];
    if (self) {
        _distribution = nil;
        _version = ZincVersionInvalid;
        _updateAutomatically = NO;
    }
    return self;
}


- (NSDictionary*) dictionaryRepresentation
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:3];
    if (self.distribution != nil)
        dict[kCodingKey_Distribution] = self.distribution;
    dict[kCodingKey_Version] = @(self.version);
    dict[kCodingKey_UpdateAutomatically] = @(self.updateAutomatically);
    if (self.flavor != nil)
        dict[kCodingKey_Flavor] = self.flavor;
    return dict;
}

- (BOOL) isEqual:(id)object
{
    if (self == object) return YES;
    
    if ([object class] != [self class]) return NO;
    
    ZincTrackingInfo* other = (ZincTrackingInfo*)object;
    
    BOOL bothDistributionsAreNil = !(self.distribution==nil) && (other.distribution==nil);
    if (!bothDistributionsAreNil && [self.distribution isEqual:other.distribution]) {
        return NO;
    }
    if (self.version != other.version) {
        return NO;
    }
    if (self.updateAutomatically != other.updateAutomatically) {
        return NO;
    }
    if (self.flavor != nil || other.flavor != nil) {
        if (![self.flavor isEqual:other.flavor]) {
            return NO;
        }
    }
    
    return YES;
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@: %p distro=%@ version=%d flavor=%@ updateAutomatically=%d>",
            [self class], self, self.distribution, self.version, self.flavor, self.updateAutomatically];
}


@end
