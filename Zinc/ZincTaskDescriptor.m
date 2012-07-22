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
@property (nonatomic, retain, readwrite) NSString* action;
@property (nonatomic, retain, readwrite) NSString* method;
@end

@implementation ZincTaskDescriptor

@synthesize resource = _resource;
@synthesize action = _action;
@synthesize method = _method;

- (id) initWithResource:(NSURL*)resource action:(NSString*)action method:(NSString*)method
{
    self = [super init];
    if (self) {
        self.resource = resource;
        self.action = action;
        self.method = method;
    }
    return self;
}

+ (id) taskDescriptorWithResource:(NSURL*)resource action:(NSString*)action method:(NSString*)method
{
    return [[[self alloc] initWithResource:resource action:action method:method] autorelease];
}

- (void)dealloc 
{
    [_resource release];
    [_action release];
    [_method release];
    [super dealloc];
}

- (NSString*) stringValue
{
    return [NSString stringWithFormat:@"Resource=%@;Action=%@;Method=%@", 
            [self.resource absoluteString], self.action, self.method];
}

- (id)copyWithZone:(NSZone *)zone
{
    ZincTaskDescriptor* newdesc = [[ZincTaskDescriptor allocWithZone:zone] init];
    newdesc.resource = [[self.resource copyWithZone:zone] autorelease];
    newdesc.action = [[self.action copyWithZone:zone] autorelease];
    newdesc.method = [[self.method copyWithZone:zone] autorelease];
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
    if (![other.action isEqual:self.action]) {
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
