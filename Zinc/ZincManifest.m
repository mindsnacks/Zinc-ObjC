//
//  ZCManifest.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//


#import "ZincManifest.h"
#import "ZincJSONSerialization.h"
#import "ZincResource.h"

@interface ZincManifest ()
@property (nonatomic, retain) NSMutableDictionary* files;
@end

@implementation ZincManifest

@synthesize bundleName = _bundleName;
@synthesize catalogId = _catalogId;
@synthesize version = _version;
@synthesize files = _files;

- (id) initWithDictionary:(NSDictionary*)dict;
{
    self = [super init];
    if (self) {
        self.bundleName = [dict objectForKey:@"bundle"];
        self.catalogId = [dict objectForKey:@"catalog"];
        self.version = [[dict objectForKey:@"version"] integerValue];
        self.files = [[[dict objectForKey:@"files"] mutableCopy] autorelease];
    }
    return self;
}

- (id)init 
{
    self = [super init];
    if (self) {
        self.files = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (ZincManifest*) manifestWithPath:(NSString*)path error:(NSError**)outError
{
    NSData* jsonData = [NSData dataWithContentsOfFile:path options:0 error:outError];
    if (jsonData == nil) {
        return nil;
    }
    
    NSDictionary* manifestDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:outError];
    if (manifestDict == nil) {
        return nil;
    }
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:manifestDict] autorelease];
    return manifest;
}

- (void)dealloc
{
    [_catalogId release];
    [_bundleName release];
    [_files release];
    [super dealloc];
}

- (NSString*) bundleId
{
    return [NSString stringWithFormat:@"%@.%@", self.catalogId, self.bundleName];
}

- (NSString*) shaForFile:(NSString*)path
{
    return [[self.files objectForKey:path] objectForKey:@"sha"];
}

- (NSArray*) formatsForFile:(NSString*)path
{
    return [[[self.files objectForKey:path] objectForKey:@"formats"] allKeys];
}

- (NSString*) bestFormatForFile:(NSString*)path withPreferredFormats:(NSArray*)preferredFormats
{
    NSArray* formats = [self formatsForFile:path];
    for (NSString* preferredFormat in preferredFormats) {
        if ([formats containsObject:preferredFormat]) {
            return preferredFormat;
        }
    }
    return nil;
}

- (NSString*) bestFormatForFile:(NSString*)path
{
    return [self bestFormatForFile:path withPreferredFormats:[NSArray arrayWithObjects:ZincFileFormatGZ, ZincFileFormatRaw, nil]];
}

- (NSUInteger) sizeForFile:(NSString*)path format:(NSString*)format 
{
    return [[[[[self.files objectForKey:path] 
               objectForKey:@"formats"] 
              objectForKey:format ]
             objectForKey:@"size"] unsignedIntegerValue];
}

- (NSArray*) allFiles
{
    return [self.files allKeys];
}

- (NSArray*) allSHAs
{
    return [[self.files allValues] valueForKeyPath:@"sha"];
}

- (NSUInteger) fileCount
{
    return [self.files count];
}

- (NSURL*) bundleResource
{
    return [NSURL zincResourceForBundleWithId:self.bundleId version:self.version];
}

- (NSDictionary*) dictionaryRepresentation
{            
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithCapacity:3];
    [d setObject:self.bundleName forKey:@"bundle"];
    [d setObject:self.catalogId forKey:@"catalog"];
    [d setObject:[NSNumber numberWithInteger:self.version] forKey:@"version"];
    [d setObject:self.files forKey:@"files"];
    return d;
}

// TODO: refactor
- (NSData*) jsonRepresentation:(NSError**)outError
{
    return [ZincJSONSerialization dataWithJSONObject:[self dictionaryRepresentation] options:0 error:outError];
}


@end
