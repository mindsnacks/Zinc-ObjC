//
//  ZincTrackingRefTest.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTrackingRefTest.h"
#import "ZincTrackingRef.h"

@implementation ZincTrackingRefTest

- (void) _testDictionaryRoundtrip:(ZincTrackingRef*)trackingRef
{
    NSDictionary* dict = [trackingRef dictionaryRepresentation];
    ZincTrackingRef* ref2 = [ZincTrackingRef trackingRefFromDictionary:dict];
    STAssertEqualObjects(trackingRef, ref2, @"objects should be equal");
}

- (void) testBasicEquality
{
    ZincTrackingRef* r1 = [[[ZincTrackingRef alloc] init] autorelease];
    ZincTrackingRef* r2 = [[[ZincTrackingRef alloc] init] autorelease];
    
    STAssertEqualObjects(r1, r2, @"empty objects should be equal");
}

- (void) testReturnsNilDict
{
    ZincTrackingRef* r1 = [ZincTrackingRef trackingRefFromDictionary:nil];
    STAssertNil(r1, @"should be nil");
}

@end
