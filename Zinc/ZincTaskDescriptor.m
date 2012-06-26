//
//  ZincTaskDescriptor.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTaskDescriptor.h"
#import "ZincResource.h"

@interface ZincTaskDescriptor ()
@property (nonatomic, retain, readwrite) NSURL* resource;
@property (nonatomic, retain, readwrite) NSString* method;
@end

@implementation ZincTaskDescriptor

@synthesize resource = _resource;
@synthesize method = _method;

- (id) initWithResource:(NSURL*)resource method:(NSString*)method
{
    self = [super init];
    if (self) {
        self.resource = resource;
        self.method = method;
    }
    return self;
}

+ (id) taskDescriptorWithResource:(NSURL*)resource method:(NSString*)method
{
    return [[[self alloc] initWithResource:resource method:method] autorelease];
}

- (void)dealloc 
{
    [_resource release];
    [_method release];
    [super dealloc];
}

- (NSString*) stringValue
{
    return [NSString stringWithFormat:@"%@|%@", [self.resource absoluteString], self.method];
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

- (NSString*) description
{
    return [self stringValue];
}

@end
