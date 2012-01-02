//
//  ZincOperationProxy.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/2/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperationProxy.h"

@interface ZincOperationProxy ()
@property (nonatomic, retain, readwrite) NSOperation* operation;
@property (nonatomic, retain) NSMutableDictionary* attributes;
@end

@implementation ZincOperationProxy

@synthesize operation = _operation;
@synthesize owner = _owner;
@synthesize attributes = _attributes;

- (id) initWithOperation:(NSOperation*)operation
{
    self.operation = operation;
    self.attributes = [NSMutableDictionary dictionary];
    return self;
}

+ (ZincOperationProxy*) proxyForOperation:(NSOperation*)operation
{
    return [[[self alloc] initWithOperation:operation] autorelease];
}

- (NSDictionary*) attributes
{
    return self.attributes;
}

- (void) addAttribute:(id)attribute forKey:(NSString*)key
{
    [self.attributes setObject:attribute forKey:key];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [(id)self.operation methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation setTarget:self.operation];
    [anInvocation invoke];
}

@end
