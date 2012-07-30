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

#import "ZincTrackingRef.h"

@implementation ZincTrackingRef

@synthesize distribution = _distribution;
@synthesize version = _version;
@synthesize updateAutomatically = _updateAutomatically;

+ (ZincTrackingRef*) trackingRefWithDistribution:(NSString*)distribution
                             updateAutomatically:(BOOL)updateAutomatically
{
    ZincTrackingRef* ref = [[[ZincTrackingRef alloc] init] autorelease];
    ref.distribution = distribution;
    ref.version = ZincVersionInvalid;
    ref.updateAutomatically = updateAutomatically;
    return ref;
}

+ (ZincTrackingRef*) trackingRefWithDistribution:(NSString*)distribution
                                         version:(ZincVersion)version
{
    ZincTrackingRef* ref = [[[ZincTrackingRef alloc] init] autorelease];
    ref.distribution = distribution;
    ref.version = version;
    ref.updateAutomatically = NO;
    return ref;
}

+ (ZincTrackingRef*) trackingRefFromDictionary:(NSDictionary*)dict
{
    if (dict == nil) return nil;
    
    ZincTrackingRef* ref = [[[ZincTrackingRef alloc] init] autorelease];
    ref.distribution = [dict objectForKey:kCodingKey_Distribution];
    ref.version = [[dict objectForKey:kCodingKey_Version] integerValue];
    ref.updateAutomatically = [[dict objectForKey:kCodingKey_UpdateAutomatically] boolValue];
    return ref;
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

- (void)dealloc
{
    [_distribution release];
    [super dealloc];
}

- (NSDictionary*) dictionaryRepresentation
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict setObject:self.distribution forKey:kCodingKey_Distribution];
    [dict setObject:[NSNumber numberWithInteger:self.version] forKey:kCodingKey_Version];
    [dict setObject:[NSNumber numberWithBool:self.updateAutomatically] forKey:kCodingKey_UpdateAutomatically];
    return dict;
}

- (BOOL) isEqual:(id)object
{
    if (self == object) return YES;
    
    if ([object class] != [self class]) return NO;
    
    ZincTrackingRef* other = (ZincTrackingRef*)object;
    
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
    
    return YES;
}

@end
