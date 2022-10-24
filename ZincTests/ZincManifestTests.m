//
//  ZincManifestTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincManifest.h"
#import "ZincJSONSerialization.h"


@interface ZincManifestTests : XCTestCase
@end


@implementation ZincManifestTests

- (void) testReadFromJson1
{
    NSError* error = nil;
    
    NSString *path = TEST_RESOURCE_PATH(@"meep-1.json");
    
    NSData* jsonData = [[[NSData alloc] initWithContentsOfFile:path options:0 error:&error] autorelease];
    if (jsonData == nil) {
        XCTFail(@"%@", error);
    }
                    
    NSDictionary* dict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (dict == nil) {
        XCTFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        XCTFail(@"manifest didn't load");
    }
    
    NSString* sha = [manifest shaForFile:@"tmp9GuVWu"];
    XCTAssertEqualObjects(sha, @"697948fc09f23a83e9755b4ed42ddd1ad489d408", @"sha is wrong");
    
    NSArray* allSHAs = [manifest allSHAs];
    XCTAssertTrue([allSHAs count] == 1, @"count wrong");
    
    NSString* firstSHA = [allSHAs objectAtIndex:0];
    XCTAssertEqualObjects(firstSHA, @"697948fc09f23a83e9755b4ed42ddd1ad489d408", @"sha is wrong");
    
    NSArray* allFormats = [manifest formatsForFile:@"tmp9GuVWu"];
    XCTAssertTrue([allFormats count] == 1, @"count wrong");
    
    NSString* firstFormat = [allFormats objectAtIndex:0];
    XCTAssertEqualObjects(firstFormat, ZincFileFormatGZ, @"format is wrong");
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
        XCTFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        XCTFail(@"manifest didn't load");
    }

    NSString* bestFormat = [manifest bestFormatForFile:@"meep.jpg"];
    XCTAssertTrue([bestFormat isEqualToString:ZincFileFormatRaw], @"should be raw");
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
        XCTFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        XCTFail(@"manifest didn't load");
    }
    
    NSString* bestFormat = [manifest bestFormatForFile:@"meep.jpg" withPreferredFormats:[NSArray arrayWithObjects:ZincFileFormatGZ, ZincFileFormatRaw, nil]];
    XCTAssertTrue([bestFormat isEqualToString:ZincFileFormatGZ], @"should be gz");
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
        XCTFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        XCTFail(@"manifest didn't load");
    }
    
    NSString* bestFormat = [manifest bestFormatForFile:@"meep.jpg" withPreferredFormats:[NSArray arrayWithObjects:ZincFileFormatGZ, ZincFileFormatRaw, nil]];
    XCTAssertTrue([bestFormat isEqualToString:ZincFileFormatGZ], @"should be gz");
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
        XCTFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        XCTFail(@"manifest didn't load");
    }

    NSUInteger size = [manifest sizeForFile:@"meep.jpg" format:ZincFileFormatGZ];
    XCTAssertTrue(size == 123, @"size is wrong");
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
        XCTFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        XCTFail(@"manifest didn't load");
    }
    
    NSArray* expectedFlavors = [NSArray arrayWithObjects:@"small", @"large", nil];
    XCTAssertEqualObjects(manifest.flavors, expectedFlavors, @"fail");
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
        XCTFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        XCTFail(@"manifest didn't load");
    }

    NSArray* expectedFlavors = [NSArray arrayWithObjects:@"small",  nil];
    XCTAssertEqualObjects([manifest flavorsForFile:@"meep.jpg"], expectedFlavors, @"fail");
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
        XCTFail(@"%@", error);
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:dict] autorelease];
    if (manifest == nil) {
        XCTFail(@"manifest didn't load");
    }
    
    NSArray* smallFiles = [manifest filesForFlavor:@"small"];
    XCTAssertTrue([smallFiles count]==1, @"2 small files");
    
    NSArray* largeFiles = [manifest filesForFlavor:@"large"];
    XCTAssertTrue([largeFiles count]==0, @"0 large files");
    
    NSArray* allFiles = [manifest filesForFlavor:nil];
    XCTAssertTrue([allFiles count]==2, @"2 files");
}

- (ZincManifest*) _manifestForDictionaryRepresentationTest
{
    ZincManifest* manifest = [[[ZincManifest alloc] init] autorelease];
    manifest.catalogID = @"com.mindsnacks.food";
    manifest.bundleName = @"pork";
    manifest.version = 5;
    return manifest;
}

- (void) testDictionaryRepresentation_bundleName
{
    ZincManifest* manifest = [self _manifestForDictionaryRepresentationTest];
    
    NSDictionary* dict = [manifest dictionaryRepresentation];

    XCTAssertEqualObjects([dict objectForKey:@"bundle"], manifest.bundleName, @"bundle name doesn't match");
}

- (void) testDictionaryRepresentation_catalogID
{
    ZincManifest* manifest = [self _manifestForDictionaryRepresentationTest];
    
    NSDictionary* dict = [manifest dictionaryRepresentation];
    
    XCTAssertEqualObjects([dict objectForKey:@"catalog"], manifest.catalogID, @"catalog id doesn't match");
}

- (void) testDictionaryRepresentation_version
{
    ZincManifest* manifest = [self _manifestForDictionaryRepresentationTest];
    
    NSDictionary* dict = [manifest dictionaryRepresentation];
    
    XCTAssertEqual((ZincVersion)[[dict objectForKey:@"version"] integerValue], manifest.version, @"version doesn't match");
}

- (void) testDictionaryRepresentation_flavors_nil
{
    ZincManifest* manifest = [self _manifestForDictionaryRepresentationTest];
    
    NSDictionary* dict = [manifest dictionaryRepresentation];
    
    XCTAssertEqual((id)[dict objectForKey:@"flavors"], manifest.flavors, @"flavors don't match");
}

- (void) testDictionaryRepresentation_flavors_notNil
{
    ZincManifest* manifest = [self _manifestForDictionaryRepresentationTest];
    manifest.flavors = @[@"chop", @"bacon"];
    
    NSDictionary* dict = [manifest dictionaryRepresentation];
    
    XCTAssertEqual((id)[dict objectForKey:@"flavors"], manifest.flavors, @"flavors don't match");
}

- (void) testRebuildFlavorsFromFiles
{
    NSDictionary* manifestDict = @{
        @"catalog": @"com.mindsnacks.food",
        @"bundle" : @"pork",
        @"version": @5,
        @"files":
            @{ @"1.png":
                @{ @"flavors": @[@"pork"]
            }
        }
    };
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:manifestDict] autorelease];
    
    XCTAssertEqualObjects(manifest.flavors, @[@"pork"], @"should have built flavors from files");
}

@end
