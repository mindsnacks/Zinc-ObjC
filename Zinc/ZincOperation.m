//
//  ZincOperation.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/2/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperation.h"
#import "ZincOperation+Private.h"

@interface ZincOperation ()
@property (nonatomic, readwrite, assign) ZincClient* client;
//@property (nonatomic, readwrite, retain) NSError* error;
@end


@implementation ZincOperation

@synthesize client = _client;
@synthesize error = _error;

- (id) initWithClient:(ZincClient*)client;
{
    self = [super init];
    if (self) {
        self.client = client;
    }
    return self;
}

- (void)dealloc 
{
    self.client = nil;
    self.error = nil;
    [super dealloc];
}

- (NSString*) descriptor
{
    //NSAssert(NO, @"must override");
    return nil;
}

- (double) progress;
{
    return 0.0;
}

@end
