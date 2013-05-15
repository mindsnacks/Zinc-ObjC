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
@property (nonatomic, strong) NSMutableDictionary* files;
@end

@implementation ZincManifest

@synthesize bundleName = _bundleName;
@synthesize catalogID = _catalogID;
@synthesize version = _version;
@synthesize files = _files;
@synthesize flavors = _flavors;

- (id) initWithDictionary:(NSDictionary*)dict;
{
    self = [super init];
    if (self) {
        self.bundleName = dict[@"bundle"];
        self.catalogID = dict[@"catalog"];
        self.version = [dict[@"version"] integerValue];
        self.files = dict[@"files"];
        self.flavors = dict[@"flavors"];
        
        if (self.flavors == nil) {  // try to build flavors for files
            
            NSMutableSet* flavorSet = [NSMutableSet set];
            
            [self.files enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSArray* fileFlavors = obj[@"flavors"];
                if (fileFlavors != nil) {
                    [flavorSet addObjectsFromArray:fileFlavors];
                }
            }];
            
            self.flavors = [flavorSet allObjects];
        }
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
    ZincManifest* manifest = [[ZincManifest alloc] initWithDictionary:manifestDict];
    return manifest;
}


- (NSString*) bundleID
{
    return [NSString stringWithFormat:@"%@.%@", self.catalogID, self.bundleName];
}

- (NSString*) shaForFile:(NSString*)path
{
    return (self.files)[path][@"sha"];
}

- (NSArray*) formatsForFile:(NSString*)path
{
    return [(self.files)[path][@"formats"] allKeys];
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
    return [self bestFormatForFile:path withPreferredFormats:@[ZincFileFormatGZ, ZincFileFormatRaw]];
}

- (NSUInteger) sizeForFile:(NSString*)path format:(NSString*)format 
{
    return [(self.files)[path][@"formats"][format][@"size"] unsignedIntegerValue];
}

- (NSArray*) flavorsForFile:(NSString*)path
{
    NSDictionary* fileDict = (self.files)[path];
    return fileDict[@"flavors"];
}

- (NSArray*) allFiles
{
    return [self.files allKeys];
}

- (NSArray*) filesForFlavor:(NSString*)flavor
{
    if (flavor == nil || ![self.flavors containsObject:flavor]) {
        return [self allFiles];
    }
    
    return [[self allFiles] filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:
             ^BOOL(id evaluatedObject, NSDictionary *bindings) {
                 NSArray* flavorsForFile = [self flavorsForFile:evaluatedObject];
                 return [flavorsForFile containsObject:flavor];
             }]];
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
    return [NSURL zincResourceForBundleWithID:self.bundleID version:self.version];
}

- (NSDictionary*) dictionaryRepresentation
{            
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithCapacity:3];
    d[@"bundle"] = self.bundleName;
    d[@"catalog"] = self.catalogID;
    d[@"version"] = @(self.version);
    d[@"files"] = self.files;
    if (self.flavors != nil) d[@"flavors"] = self.flavors;
    return d;
}

// TODO: refactor
- (NSData*) jsonRepresentation:(NSError**)outError
{
    return [ZincJSONSerialization dataWithJSONObject:[self dictionaryRepresentation] options:0 error:outError];
}


@end
