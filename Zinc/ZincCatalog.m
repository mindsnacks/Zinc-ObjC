//
//  ZCIndex.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/16/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincCatalog.h"
#import "ZincKSJSON.h"

@implementation ZincCatalog

@synthesize identifier = _identifier;
@synthesize format = _format;
@synthesize bundleInfoById = _bundleInfoById;

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [_identifier release];
    [_bundleInfoById release];
    [super dealloc];
}

#pragma mark Encoding

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if (self) {
        self.identifier = [dict objectForKey:@"id"]; 
        self.format = [[dict objectForKey:@"format"] integerValue];
        self.bundleInfoById = [dict objectForKey:@"bundles"];
    }
    return self;
}

- (NSDictionary*) dictionaryRepresentation
{
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithCapacity:4];
    [d setObject:self.identifier forKey:@"id"];
    [d setObject:[NSNumber numberWithInteger:self.format] forKey:@"format"];
    [d setObject:self.bundleInfoById forKey:@"bundles"];
    return d;
}

// TODO: refactor
- (NSString*) jsonRepresentation:(NSError**)outError
{
    return [ZincKSJSON serializeObject:[self dictionaryRepresentation] error:outError];
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@ 0x%x\n%@>",
			NSStringFromClass([self class]),
			(unsigned int)self,
            [self dictionaryRepresentation]];
}

#pragma mark -

- (NSInteger) versionForBundleId:(NSString*)bundleId distribution:(NSString*)distro
{
    NSDictionary* bundleInfo = [self.bundleInfoById objectForKey:bundleId];
    
    NSNumber* version = [[bundleInfo objectForKey:@"distributions"]
                         objectForKey:distro];
    if (version != nil) {
        return [version integerValue];
    }
    return ZincVersionInvalid;
}

@end

// TODO: rename, break out, etc
@implementation ZincCatalog (JSON)
 
+ (ZincCatalog*) catalogFromJSONString:(NSString*)string error:(NSError**)outError
{
    id json = [ZincKSJSON deserializeString:string error:outError];
    if (json == nil) {
        return nil;
    }
    ZincCatalog* catalog = [[[ZincCatalog alloc] initWithDictionary:json] autorelease];
    return catalog;
}

@end
