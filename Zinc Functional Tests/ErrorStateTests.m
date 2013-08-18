//
//  ErrorStateTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 3/18/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincFunctionalTestCase.h"


#define DEFAULT_TIMEOUT_SECONDS 60


@interface ErrorStateTests : ZincFunctionalTestCase

@end


@implementation ErrorStateTests

- (void)testCloneWithInvalidSourceURL
{
    [self setupZincRepo];

    [self.zincRepo addSourceURL:[NSURL URLWithString:@"http://thisdoesnotexist.pants"]];
    
    NSString *bundleID = @"com.mindsnacks.demo.cats";
    
    [self.zincRepo beginTrackingBundleWithID:bundleID distribution:@"master"];
    
    [self prepare];
    [self.zincRepo updateBundleWithID:bundleID completionBlock:^(NSArray *errors) {
        if ([errors count] > 0) {
            GHTestLog(@"%@", errors);
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];
    // we expect it to fail
    [self waitForStatus:kGHUnitWaitStatusFailure timeout:DEFAULT_TIMEOUT_SECONDS];
}

@end
