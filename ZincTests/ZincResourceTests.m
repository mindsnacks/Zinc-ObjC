//
//  ZincResourceTests.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincResource.h"


@interface ZincResourceTests : XCTestCase
@end


@implementation ZincResourceTests


- (void) testCatalogResource
{
    NSURL* catalogResource = [NSURL zincResourceForCatalogWithId:@"com.mindsnacks"];
  
    XCTAssertTrue([[catalogResource zincCatalogID] isEqualToString:@"com.mindsnacks"],
                 @"catalogID wrong");
}

- (void) testBundleResource
{
    NSURL* bundleResource = [NSURL zincResourceForBundleWithID:@"com.mindsnacks.demo" version:1];
    
    NSString* catalogID = [bundleResource zincCatalogID];
    XCTAssertTrue([catalogID isEqual:@"com.mindsnacks"], @"catalog wrong");
}

@end
