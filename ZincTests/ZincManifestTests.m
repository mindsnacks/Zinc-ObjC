//
//  ZincManifestTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincManifestTests.h"
#import "ZincManifest.h"
#import "ZincKSJSON.h"

@implementation ZincManifestTests

- (void) testReadFromJson1
{
    NSError* error = nil;
    
    NSString* path = TEST_RESOURCE_PATH(@"meep-1.json");
    
    NSString* jsonString = [[[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error] autorelease];
    if (jsonString == nil) {
        STFail(@"%@", error);
    }
                    
    NSDictionary* dict = [ZincKSJSON deserializeString:jsonString error:&error];
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

- (void) testBestFormatForFileRawOnly
{
    NSString* jsonString = 
    @"{ \
        \"files\": { \
            \"meep.jpg\": { \
                \"sha\": \"e9185889564c9af0968ee60a7d7771dcfc19f888\", \
                \"formats\": { \
                    \"raw\": { \
                        \"size\": 3578 \
                    } \
                } \
            } \
        }, \
        \"version\": 1, \
        \"bundle\": \"Test\" \
    }";
    
    NSError* error = nil;
    NSDictionary* dict = [ZincKSJSON deserializeString:jsonString error:&error];
    if (dict == nil) {
        STFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        STFail(@"manifest didn't load");
    }

    NSString* bestFormat = [manifest bestFormatForFile:@"meep.jpg"];
    STAssertTrue([bestFormat isEqualToString:ZincFileFormatRaw], @"should be raw");
}

- (void) testBestFormatForFileGZOnly
{
    NSString* jsonString = 
    @"{ \
        \"files\": { \
            \"meep.jpg\": { \
                \"sha\": \"e9185889564c9af0968ee60a7d7771dcfc19f888\", \
                \"formats\": { \
                    \"gz\": { \
                        \"size\": 3578 \
                    } \
                } \
            } \
        }, \
        \"version\": 1, \
        \"bundle\": \"Test\" \
    }";
    
    NSError* error = nil;
    NSDictionary* dict = [ZincKSJSON deserializeString:jsonString error:&error];
    if (dict == nil) {
        STFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        STFail(@"manifest didn't load");
    }
    
    NSString* bestFormat = [manifest bestFormatForFile:@"meep.jpg" withPreferredFormats:[NSArray arrayWithObjects:ZincFileFormatGZ, ZincFileFormatRaw, nil]];
    STAssertTrue([bestFormat isEqualToString:ZincFileFormatGZ], @"should be gz");
}

- (void) testBestFormatForFileGZAndRaw
{
    NSString* jsonString = 
    @"{ \
        \"files\": { \
            \"meep.jpg\": { \
                \"sha\": \"e9185889564c9af0968ee60a7d7771dcfc19f888\", \
                \"formats\": { \
                    \"raw\": { \
                        \"size\": 3578 \
                    }, \
                    \"gz\": { \
                        \"size\": 123 \
                    } \
                } \
            } \
        }, \
        \"version\": 1, \
        \"bundle\": \"Test\" \
    }";
    
    NSError* error = nil;
    NSDictionary* dict = [ZincKSJSON deserializeString:jsonString error:&error];
    if (dict == nil) {
        STFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        STFail(@"manifest didn't load");
    }
    
    NSString* bestFormat = [manifest bestFormatForFile:@"meep.jpg" withPreferredFormats:[NSArray arrayWithObjects:ZincFileFormatGZ, ZincFileFormatRaw, nil]];
    STAssertTrue([bestFormat isEqualToString:ZincFileFormatGZ], @"should be gz");
}

- (void) testFileSize
{
    NSString* jsonString = 
    @"{ \
        \"files\": { \
            \"meep.jpg\": { \
                \"sha\": \"e9185889564c9af0968ee60a7d7771dcfc19f888\", \
                \"formats\": { \
                    \"raw\": { \
                        \"size\": 3578 \
                    }, \
                    \"gz\": { \
                        \"size\": 123 \
                    } \
                } \
            } \
        }, \
        \"version\": 1, \
        \"bundle\": \"Test\" \
    }";
    
    NSError* error = nil;
    NSDictionary* dict = [ZincKSJSON deserializeString:jsonString error:&error];
    if (dict == nil) {
        STFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        STFail(@"manifest didn't load");
    }

    NSUInteger size = [manifest sizeForFile:@"meep.jpg" format:ZincFileFormatGZ];
    STAssertTrue(size == 123, @"size is wrong");
}

@end
