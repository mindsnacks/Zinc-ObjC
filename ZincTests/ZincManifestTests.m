//
//  ZincManifestTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincManifestTests.h"
#import "ZincManifest.h"
#import "ZincJSONSerialization.h"

@implementation ZincManifestTests

- (void) testReadFromJson1
{
    NSError* error = nil;
    
    NSString* path = TEST_RESOURCE_PATH(@"meep-1.json");
    
    NSData* jsonData = [[[NSData alloc] initWithContentsOfFile:path options:0 error:&error] autorelease];
    if (jsonData == nil) {
        STFail(@"%@", error);
    }
                    
    NSDictionary* dict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
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
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* dict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
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
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* dict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
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
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* dict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
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
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* dict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
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

- (void) testReadGlobalFlavors
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
        \"bundle\": \"Test\", \
        \"flavors\": [\"small\", \"large\"] \
    }";
    
    NSError* error = nil;
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* dict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (dict == nil) {
        STFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        STFail(@"manifest didn't load");
    }
    
    NSArray* expectedFlavors = [NSArray arrayWithObjects:@"small", @"large", nil];
    STAssertEqualObjects(manifest.flavors, expectedFlavors, @"fail");
}

- (void) testReadFileFlavors
{
    NSString* jsonString = 
    @"{ \
        \"files\": { \
            \"meep.jpg\": { \
                \"sha\": \"e9185889564c9af0968ee60a7d7771dcfc19f888\", \
                \"flavors\": [\"small\"], \
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
        \"bundle\": \"Test\", \
        \"flavors\": [\"small\", \"large\"] \
    }";
    
    NSError* error = nil;
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* dict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (dict == nil) {
        STFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        STFail(@"manifest didn't load");
    }

    NSArray* expectedFlavors = [NSArray arrayWithObjects:@"small",  nil];
    STAssertEqualObjects([manifest flavorsForFile:@"meep.jpg"], expectedFlavors, @"fail");
}

- (void) testFilesForFlavor
{
    NSString* jsonString = 
    @"{ \
        \"files\": { \
            \"meep.jpg\": { \
                \"sha\": \"e9185889564c9af0968ee60a7d7771dcfc19f888\", \
                \"flavors\": [\"small\"], \
                \"formats\": { \
                    \"raw\": { \
                        \"size\": 3578 \
                    }, \
                    \"gz\": { \
                        \"size\": 123 \
                    } \
                } \
            }, \
            \"meep2.jpg\": { \
                \"sha\": \"e9185889564c9af0968ee60a7d7771dcfc19f889\", \
                \"flavors\": [], \
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
        \"bundle\": \"Test\", \
        \"flavors\": [\"small\", \"large\"] \
    }";
    
    NSError* error = nil;
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* dict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (dict == nil) {
        STFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        STFail(@"manifest didn't load");
    }
    
    NSArray* smallFiles = [manifest filesForFlavor:@"small"];
    STAssertTrue([smallFiles count]==1, @"2 small files");
    
    NSArray* largeFiles = [manifest filesForFlavor:@"large"];
    STAssertTrue([largeFiles count]==0, @"0 large files");
    
    NSArray* allFiles = [manifest filesForFlavor:nil];
    STAssertTrue([allFiles count]==2, @"2 files");
}

- (ZincManifest*) _manifestForDictionaryRepresentationTest
{
    ZincManifest* manifest = [[[ZincManifest alloc] init] autorelease];
    manifest.catalogId = @"com.mindsnacks.food";
    manifest.bundleName = @"pork";
    manifest.version = 5;
    return manifest;
}

- (void) testDictionaryRepresentation_bundleName
{
    ZincManifest* manifest = [self _manifestForDictionaryRepresentationTest];
    
    NSDictionary* dict = [manifest dictionaryRepresentation];

    STAssertEqualObjects([dict objectForKey:@"bundle"], manifest.bundleName, @"bundle name doesn't match");
}

- (void) testDictionaryRepresentation_catalogID
{
    ZincManifest* manifest = [self _manifestForDictionaryRepresentationTest];
    
    NSDictionary* dict = [manifest dictionaryRepresentation];
    
    STAssertEqualObjects([dict objectForKey:@"catalog"], manifest.catalogId, @"catalog id doesn't match");
}

- (void) testDictionaryRepresentation_version
{
    ZincManifest* manifest = [self _manifestForDictionaryRepresentationTest];
    
    NSDictionary* dict = [manifest dictionaryRepresentation];
    
    STAssertEquals((ZincVersion)[[dict objectForKey:@"version"] integerValue], manifest.version, @"version doesn't match");
}

- (void) testDictionaryRepresentation_flavors_nil
{
    ZincManifest* manifest = [self _manifestForDictionaryRepresentationTest];
    
    NSDictionary* dict = [manifest dictionaryRepresentation];
    
    STAssertEquals((id)[dict objectForKey:@"flavors"], manifest.flavors, @"flavors don't match");
}

- (void) testDictionaryRepresentation_flavors_notNil
{
    ZincManifest* manifest = [self _manifestForDictionaryRepresentationTest];
    manifest.flavors = @[@"chop", @"bacon"];
    
    NSDictionary* dict = [manifest dictionaryRepresentation];
    
    STAssertEquals((id)[dict objectForKey:@"flavors"], manifest.flavors, @"flavors don't match");
}

@end
