//
//  ZincEvent.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/6/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincEvent.h"

@interface ZincEvent ()
@property (nonatomic, assign, readwrite) ZincEventType type;
@property (nonatomic, retain, readwrite) id source;
@property (nonatomic, retain, readwrite) NSDate* timestamp;
@end

@implementation ZincEvent

@synthesize type = _type;
@synthesize source = _source;
@synthesize timestamp = _timestamp;

- (id) initWithType:(ZincEventType)type source:(id)source
{
    self = [super init];
    if (self) {
        self.type = type;
        self.source = source;
        self.timestamp = [NSDate date];
    }
    return self;
}

- (void)dealloc
{
    self.source = nil;
    [super dealloc];
}

@end

#pragma mark -

@interface ZincErrorEvent ()
@property (nonatomic, retain, readwrite) NSError* error;
@end

@implementation ZincErrorEvent

@synthesize error = _error;

- (id) initWithError:(NSError*)error source:(id)source
{
    self = [super initWithType:ZincEventTypeError source:source];
    if (self) {
        self.error = error;
    }
    return self;
}

- (void)dealloc
{
    self.error = nil;
    [super dealloc];
}

+ (id) eventWithError:(NSError*)error source:(id)source
{
    return [[[ZincErrorEvent alloc] initWithError:error source:source] autorelease];
}


@end
