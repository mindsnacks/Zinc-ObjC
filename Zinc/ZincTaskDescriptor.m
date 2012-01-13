//
//  ZincTaskDescriptor.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTaskDescriptor.h"
#import "ZincResource.h"

@implementation ZincTaskDescriptor

@synthesize resource = _resource;
@synthesize method = _method;

- (void)dealloc 
{
    self.resource = nil;
    self.method = nil;
    [super dealloc];
}

- (NSString*) stringValue
{
    return [NSString stringWithFormat:@"%@-%@", [self.resource absoluteString], self.method];
}

- (id)copyWithZone:(NSZone *)zone
{
    ZincTaskDescriptor* newdesc = [[ZincTaskDescriptor allocWithZone:zone] init];
    newdesc.resource = [[self.resource copy] autorelease];
    newdesc.method = [[self.method copy] autorelease];
    return newdesc;
}

- (BOOL) isEqual:(id)object
{
    if ([object class] != [self class]) {
        return NO;
    }
    
    ZincTaskDescriptor* other = (ZincTaskDescriptor*)object;
    if (![other.resource isEqual:self.resource]) {
        return NO;
    }
    if (![other.method isEqual:self.method]) {
        return NO;
    }
    
    return YES;    
}

- (NSUInteger)hash
{
    return [[self stringValue] hash];
}

@end
