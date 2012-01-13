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

@end
