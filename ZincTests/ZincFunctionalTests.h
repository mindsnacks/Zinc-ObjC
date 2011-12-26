//
//  ZincTests.h
//  ZincTests
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class ZCFileSystem;

@interface ZincFunctionalTests : SenTestCase

@property (nonatomic, retain) ZCFileSystem* repo;

@end
