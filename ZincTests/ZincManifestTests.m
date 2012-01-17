//
//  ZincManifestTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincManifestTests.h"
#import "ZincManifest.h"
#import "KSJSON.h"

@implementation ZincManifestTests

- (void) testReadFromJson1
{
    NSError* error = nil;
    
    NSString* path = TEST_RESOURCE_PATH(@"meep-1.json");
    
    NSString* string = [[[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error] autorelease];
    if (string == nil) {
        STFail(@"%@", error);
    }
                    
    NSDictionary* dict = [KSJSON deserializeString:string error:&error];
    if (dict == nil) {
        STFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        STFail(@"manifest didn't load");
    }
    
    NSString* sha = [manifest shaForFile:@"tmp9GuVWu"];
    STAssertEqualObjects(sha, @"697948fc09f23a83e9755b4ed42ddd1ad489d408", @"sha is wrong");
    
    NSArray* allSHAs = [manifest allSHAs];
    STAssertTrue([allSHAs count] == 1, @"count wrong");
    
    NSString* firstSHA = [allSHAs objectAtIndex:0];
    STAssertEqualObjects(firstSHA, @"697948fc09f23a83e9755b4ed42ddd1ad489d408", @"sha is wrong");
    
    NSArray* allFormats = [manifest formatsForFile:@"tmp9GuVWu"];
    STAssertTrue([allFormats count] == 1, @"count wrong");
    
    NSString* firstFormat = [allFormats objectAtIndex:0];
    STAssertEqualObjects(firstFormat, ZincFileFormatGZ, @"format is wrong");
}

@end
