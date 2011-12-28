//
//  ZCIndex.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/16/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincIndex.h"

@implementation ZincIndex

@synthesize format = _format;
@synthesize bundles = _bundles;
@synthesize distributions = _distributions;

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    self.bundles = nil;
    self.distributions = nil;
    [super dealloc];
}

#pragma mark Encoding

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if (self) {
        self.format = [[dict objectForKey:@"format"] integerValue];
        self.bundles = [dict objectForKey:@"bundles"];
        self.distributions = [dict objectForKey:@"distributions"];
    }
    return self;
}

- (NSDictionary*) dictionaryRepresentation
{
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithCapacity:3];
    [d setObject:[NSNumber numberWithInteger:self.format] forKey:@"format"];
    [d setObject:self.bundles forKey:@"bundles"];
    [d setObject:self.distributions forKey:@"distributions"];
    return d;
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@ 0x%x\n%@>",
			NSStringFromClass([self class]),
			self,
            [self dictionaryRepresentation]];
}


@end
