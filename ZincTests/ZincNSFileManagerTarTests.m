//
//  ZincNSFileManagerTarTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 10/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "NSFileManager+ZincTar.h"


@interface ZincNSFileManagerTarTests : SenTestCase
@property (nonatomic, retain) NSString* myDir;
@end


@implementation ZincNSFileManagerTarTests

- (void)setUp
{
    self.myDir = TEST_CREATE_TMP_DIR(NSStringFromClass([self class]));
}

- (void)dealloc
{
    [_myDir release];
    [super dealloc];
}

- (void) testTarIsLessThanMinimumSize
{
    NSUInteger size = 1;
    uint8_t b[size];
    
    NSData* tarData = [NSData dataWithBytes:b length:size];
    
    NSError* error = nil;
    BOOL success = [[NSFileManager defaultManager] zinc_createFilesAndDirectoriesAtPath:self.myDir withTarData:tarData error:&error];
    STAssertFalse(success, @"should not have succeeded");
}

- (void) testTarHasInvalidBlockSize
{
    NSUInteger size = 512*2 + 1;
    uint8_t b[size];
    
    NSData* tarData = [NSData dataWithBytes:b length:size];
    
    NSError* error = nil;
    BOOL success = [[NSFileManager defaultManager] zinc_createFilesAndDirectoriesAtPath:self.myDir withTarData:tarData error:&error];
    STAssertFalse(success, @"should not have succeeded");
}

@end
