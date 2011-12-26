//
//  ZincTests.m
//  ZincTests
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincFunctionalTests.h"
#import "ZCFileSystem.h"

@implementation ZincFunctionalTests

@synthesize repo = _repo;

- (void)setUp
{
    [super setUp];

    NSError* error = nil;
    ZCFileSystem* repo = [ZCFileSystem fileSystemWithURL:[NSURL fileURLWithPath:TEST_RESOURCE_PATH(@"testrepo1")] error:&error];
    if (repo == nil) {
        STFail(@"%@", error);
    }
    self.repo = repo;
//    self.bundle.version = 1;
}

- (void) testRepoLoadBasic
{
    
}

//- (void) testPathSimple
//{
//    NSString* path = [self.bundle pathForResource:@"a.txt"];
//    STAssertNotNil(path, @"path is nil");
//    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
//    STAssertTrue(exists, @"file does not exist");
//}

//- (void) testPathLessSimple
//{
//    NSString* path = [self.bundle pathForResource:@"1/b.txt"];
//    STAssertNotNil(path, @"path is nil");
//    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
//    STAssertTrue(exists, @"file does not exist");
//}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

@end
