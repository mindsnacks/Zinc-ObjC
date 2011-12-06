//
//  ZincTests.m
//  ZincTests
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincFunctionalTests.h"
#import "ZCBundle.h"

@implementation ZincFunctionalTests

@synthesize bundle = _bundle;

- (void)setUp
{
    [super setUp];

    NSError* error = nil;
    ZCBundle* bundle = [ZCBundle bundleWithPath:TEST_RESOURCE_PATH(@"testbundle1") error:&error];
    if (bundle == nil) {
        STFail(@"%@", error);
    }
    self.bundle = bundle;
    self.bundle.version = 1;
}

- (void) testPathSimple
{
    NSString* path = [self.bundle pathForResource:@"a.txt"];
    STAssertNotNil(path, @"path is nil");
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    STAssertTrue(exists, @"file does not exist");
}

- (void) testPathLessSimple
{
    NSString* path = [self.bundle pathForResource:@"1/b.txt"];
    STAssertNotNil(path, @"path is nil");
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    STAssertTrue(exists, @"file does not exist");
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

@end
