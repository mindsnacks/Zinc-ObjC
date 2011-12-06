//
//  ZCManifest.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//


#import "ZCManifest.h"

@interface ZCManifest ()
@property (nonatomic, retain) NSDictionary* manifestDict;
@end

@implementation ZCManifest

@synthesize manifestDict = _manifestDict;

- (id) initWithDictionary:(NSDictionary*)dict;
{
    self = [super init];
    if (self) {
        self.manifestDict = dict;
    }
    return self;
}

- (void)dealloc
{
    self.manifestDict = nil;
    [super dealloc];
}

- (NSString*) version
{
    return [self.manifestDict objectForKey:@"version"];
}

- (ZincVersionMajor) majorVersion
{
    return [[[[self version] componentsSeparatedByString:@"."]
             objectAtIndex:0] integerValue];
}

- (ZincVersionMinor) minorVersion
{
    return [[[[self version] componentsSeparatedByString:@"."]
             objectAtIndex:1] integerValue];
}

- (NSString*) shaForPath:(NSString*)path
{
    return [[self.manifestDict objectForKey:@"files"] objectForKey:path];
}


@end
