//
//  ZCManifest.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//


#import "ZincManifest.h"
#import "KSJSON.h"

@interface ZincManifest ()
@property (nonatomic, retain) NSDictionary* files;
@end

@implementation ZincManifest

@synthesize bundleName = _bundleName;
@synthesize version = _version;
@synthesize files = _files;

- (id) initWithDictionary:(NSDictionary*)dict;
{
    self = [super init];
    if (self) {
        self.bundleName = [dict objectForKey:@"bundle"];
        self.version = [[dict objectForKey:@"version"] integerValue];
        self.files = [dict objectForKey:@"files"];
    }
    return self;
}

- (id)init 
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    self.bundleName = nil;
    self.files = nil;
    [super dealloc];
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

- (NSDictionary*) dictionaryRepresentation
{            
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithCapacity:3];
    [d setObject:self.bundleName forKey:@"bundle"];
    [d setObject:[NSNumber numberWithInteger:self.version] forKey:@"version"];
    [d setObject:self.files forKey:@"files"];
    return d;
}

// TODO: refactor
- (NSString*) jsonRepresentation:(NSError**)outError
{
    return [KSJSON serializeObject:[self dictionaryRepresentation] error:outError];
}


@end
