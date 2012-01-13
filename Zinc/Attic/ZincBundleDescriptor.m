//
//  ZincBundleDescriptor.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincBundleDescriptor.h"

@implementation ZincBundleDescriptor

@synthesize bundleId = _bundleId;
@synthesize version = _version;

+ (id) bundleDescriptorForId:(NSString*)bundleId version:(ZincVersion)version
{
    ZincBundleDescriptor* descr = [[[ZincBundleDescriptor alloc] init] autorelease];
    descr.bundleId = bundleId;
    descr.version = version;
    return descr;
}

- (void)dealloc
{
    self.bundleId = nil;
    [super dealloc];
}

- (NSString*) stringValue
{
    return [NSString stringWithFormat:@"%@-%d", self.bundleId, self.version];
}


- (id)copyWithZone:(NSZone *)zone
{
    ZincBundleDescriptor* newdesc = [[ZincBundleDescriptor allocWithZone:zone] init];
    newdesc.bundleId = [[self.bundleId copy] autorelease];
    newdesc.version = self.version;
    return newdesc;
}

- (BOOL) isEqual:(id)object
{
    if ([object class] != [self class]) {
        return NO;
    }
    
    ZincBundleDescriptor* other = (ZincBundleDescriptor*)object;
    if (other.version != self.version)  {
        return NO;
    }
    if (![other.bundleId isEqualToString:self.bundleId]) {
        return NO;
    }
    
    return YES;    
}

- (NSUInteger) hash
{
    return [[self stringValue] hash];
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@ 0x%x bundle:%@ version:%d>",
			NSStringFromClass([self class]),
			self,
            self.bundleId, self.version];
}


@end
