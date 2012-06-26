//
//  ZincResourceTests.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincResourceTests.h"
#import "ZincResource.h"

@implementation ZincResourceTests


- (void) testCatalogResource
{
    NSURL* catalogResource = [NSURL zincResourceForCatalogWithId:@"com.mindsnacks"];
  
    STAssertTrue([[catalogResource zincCatalogId] isEqualToString:@"com.mindsnacks"],
                 @"catalogId wrong");
}

- (void) testBundleResource
{
    NSURL* bundleResource = [NSURL zincResourceForBundleWithId:@"com.mindsnacks.demo" version:1];
    
    NSString* catalogId = [bundleResource zincCatalogId];
    STAssertTrue([catalogId isEqual:@"com.mindsnacks"], @"catalog wrong");
}

@end
