//
//  ZCIndex.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/16/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincCatalog.h"

#import "ZincJSONSerialization.h"

@interface ZincCatalog ()
@property (nonatomic, strong, readwrite) NSString* identifier;
@property (nonatomic, strong, readwrite) NSDictionary* bundleInfoByName;
@end

@implementation ZincCatalog

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}


#pragma mark Encoding

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if (self) {
        self.identifier = dict[@"id"]; 
        self.format = [dict[@"format"] integerValue];
        self.bundleInfoByName = dict[@"bundles"];
    }
    return self;
}

- (NSDictionary*) dictionaryRepresentation
{
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithCapacity:4];
    d[@"id"] = self.identifier;
    d[@"format"] = @(self.format);
    d[@"bundles"] = self.bundleInfoByName;
    return d;
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@ 0x%x\n%@>",
			NSStringFromClass([self class]),
			(unsigned int)self,
            [self dictionaryRepresentation]];
}

#pragma mark -

- (NSDictionary *)distributionsForBundleName:(NSString *)bundleName
{
    NSDictionary* bundleInfo = (self.bundleInfoByName)[bundleName];
    return [bundleInfo[@"distributions"] copy];
}


- (NSInteger) versionForBundleName:(NSString*)bundleName distribution:(NSString*)distro
{
    NSDictionary* bundleInfo = (self.bundleInfoByName)[bundleName];
    
    NSNumber* version = bundleInfo[@"distributions"][distro];
    if (version != nil) {
        return [version integerValue];
    }
    return ZincVersionInvalid;
}

@end

// TODO: rename, break out, etc
@implementation ZincCatalog (JSON)
 
+ (ZincCatalog*) catalogFromJSONData:(NSData*)data error:(NSError**)outError
{
    id json = [ZincJSONSerialization JSONObjectWithData:data options:0 error:outError];
    if (json == nil) {
        return nil;
    }
    ZincCatalog* catalog = [[ZincCatalog alloc] initWithDictionary:json];
    return catalog;
}

@end
