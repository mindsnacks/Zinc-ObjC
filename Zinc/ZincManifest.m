//
//  ZCManifest.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//


#import "ZincManifest.h"

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
        self.bundleName = [dict objectForKey:@"bundle_name"];
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
    return [self.files objectForKey:path];
}

- (NSArray*) allFiles
{
    return [self.files allKeys];
}

- (NSDictionary*) dictionaryRepresentation
{            
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithCapacity:3];
    [d setObject:self.bundleName forKey:@"bundle_name"];
    [d setObject:[NSNumber numberWithInteger:self.version] forKey:@"version"];
    [d setObject:self.files forKey:@"files"];
    return d;
}


@end
