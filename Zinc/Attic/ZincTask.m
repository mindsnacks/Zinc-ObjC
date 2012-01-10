//
//  ZincTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/5/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"
#import "ZincTask+Private.h"
#import "ZincClient+Private.h"

@interface ZincTask ()
@property (nonatomic, assign, readwrite) ZincClient* client;
@property (nonatomic, retain) NSOperation* currentRun;

@end

@implementation ZincTask

@synthesize client = _client;
@synthesize currentRun = _currentRun;

- (id) initWithClient:(ZincClient*)client
{
    self = [super init];
    if (self) {
        self.client = client;
    }
    return self;
}

- (void)dealloc 
{
    [self.currentRun cancel];
    self.currentRun = nil;
    [super dealloc];
}

- (void) start
{
    @synchronized(self) {
        if (self.currentRun == nil || [self.currentRun isFinished]) {
            self.currentRun = [self operation];
            [self.client addOperation:self.currentRun];
        }
    }
}

- (BOOL) isExecuting
{
    return [self.currentRun isExecuting];
}

- (void) cancel
{
    [self.currentRun cancel];
}

- (NSString*) key
{
    NSAssert(NO, @"must override");
    return nil;
}

- (NSOperation*) operation
{
    NSAssert(NO, @"must override");
    return nil;
}

@end
