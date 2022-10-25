//
//  ZincTrackingRefTest.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTrackingInfo.h"


@interface ZincTrackingInfoTest : XCTestCase
@end


@implementation ZincTrackingInfoTest

- (void) _testDictionaryRoundtrip:(ZincTrackingInfo*)trackingRef
{
    NSDictionary* dict = [trackingRef dictionaryRepresentation];
    ZincTrackingInfo* ref2 = [ZincTrackingInfo trackingInfoFromDictionary:dict];
    XCTAssertEqualObjects(trackingRef, ref2, @"objects should be equal");
}

- (void) testBasicEquality
{
    ZincTrackingInfo* r1 = [[[ZincTrackingInfo alloc] init] autorelease];
    ZincTrackingInfo* r2 = [[[ZincTrackingInfo alloc] init] autorelease];
    
    XCTAssertEqualObjects(r1, r2, @"empty objects should be equal");
}

- (void) testReturnsNilDict
{
    ZincTrackingInfo* r1 = [ZincTrackingInfo trackingInfoFromDictionary:nil];
    XCTAssertNil(r1, @"should be nil");
}

@end
