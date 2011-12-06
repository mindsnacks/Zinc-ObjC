//
//  ZCFileSystem.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZCFileSystem.h"
#import "KSJSON.h"
#import "ZCManifest.h"
#import "NSFileManager+Zinc.h"

#define ZINC_FORMAT_FILE @"zinc_format.txt"

@interface ZCFileSystem ()
@property (nonatomic, retain, readwrite) NSURL* url;
@property (nonatomic, retain) NSMutableDictionary* manifestsByVersion;
@end

@implementation ZCFileSystem

@synthesize url = _url;
@synthesize manifestsByVersion = _manifestsByVersion;

+ (Class) fileSystemForFormat:(NSInteger)format
{
    return self;
}

+ (ZincFormat) readZincFormatFromURL:(NSURL*)url error:(NSError**)outError
{
    NSFileManager* fm = [NSFileManager zinc_newFileManager];
    NSString* path = [[url path] stringByAppendingPathComponent:ZINC_FORMAT_FILE];
    if (![fm fileExistsAtPath:path]) {
        // file doesn't exist error
        AMErrorAssignIfNotNil(outError, ZCError(ZINC_ERR_MISSING_FORMAT_FILE));
        return ZincFormatInvalid;
    }
    
    NSString* string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:outError];
    if (string == nil) {
        return ZincFormatInvalid;
    }
    
    if ([string integerValue] == 0) {
        return ZincFormatInvalid;
    }
    
    return [string integerValue];;
}

- (id) initWithURL:(NSURL*)url
{
    self = [super init];
    if (self) {
        self.url = url;
        self.manifestsByVersion = [NSMutableDictionary dictionaryWithCapacity:3];
    }
    return self;
}

- (void)dealloc
{
    self.url = nil;
    self.manifestsByVersion = nil;
    [super dealloc];
}


+ (ZCFileSystem*) fileSystemForWithURL:(NSURL*)url error:(NSError**)outError
{
    ZincFormat format = [self readZincFormatFromURL:url error:outError];
    if (format == ZincFormatInvalid) {
        return nil;
    }
    
    Class fsClass = [self fileSystemForFormat:format];
    ZCFileSystem* zcfs = [[[fsClass alloc] initWithURL:url] autorelease];
    return zcfs;
}


- (NSString*) pathForManifestVersion:(ZincVersionMajor)version
{
    return [[[[self.url path] 
             stringByAppendingPathComponent:@"versions"]
            stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", version]]
            stringByAppendingPathComponent:@"manifest.json"];
    
}

- (ZCManifest*) readManifestForVersion:(ZincVersionMajor)version error:(NSError**)outError
{
    NSString* path = [self pathForManifestVersion:version];
    NSString* manifestString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:outError];
    if (manifestString == nil) {
        return nil;
    }
    
    id jsonObj = [KSJSON deserializeString:manifestString error:outError];
    if (jsonObj == nil) { 
        return nil;
    }
    
    if (![jsonObj isKindOfClass:[NSDictionary class]]) {
        AMErrorAssignIfNotNil(outError, ZCError(ZINC_ERR_INVALID_MANIFEST_FORMAT));
        return nil;
    }
    
    ZCManifest* manifest = [[[ZCManifest alloc] initWithDictionary:jsonObj] autorelease];
    return manifest;
}

- (NSString*) pathForResource:(NSString*)path version:(ZincVersionMajor)version
{
    ZCManifest* manifest = [self.manifestsByVersion objectForKey:[NSNumber numberWithUnsignedInteger:version]];
    if (manifest == nil) {
        @synchronized(self) {
            NSError* error = nil;
            manifest = [self readManifestForVersion:version error:&error];
            if (manifest == nil) {
                LOG_ERROR(@"%@", error);
                return nil;
            }
            [self.manifestsByVersion setObject:manifest forKey:[NSNumber numberWithUnsignedInteger:version]];
        }
    }
    
    NSString* sha = [manifest shaForPath:path];
    NSString* dir = [path stringByDeletingLastPathComponent];
    NSString* filename = [[path lastPathComponent] stringByDeletingPathExtension];
    NSString* fileext = [[path lastPathComponent] pathExtension];
    NSString* zfilename = [NSString stringWithFormat:@"%@+%@.%@", filename, sha, fileext];
    NSString* zpath = [[[[self.url path] stringByAppendingPathComponent:@"objects"]
                        stringByAppendingPathComponent:dir]
                       stringByAppendingPathComponent:zfilename];
                       
    return zpath;
}

@end
