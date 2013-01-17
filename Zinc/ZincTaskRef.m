//
//  ZincTaskRef.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/29/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTaskRef.h"
#import "ZincTask.h"

@interface ZincTaskRef ()
@property (nonatomic, retain) NSMutableArray* errors;
@end

@implementation ZincTaskRef

@synthesize errors = _errors;

- (id)init
{
    self = [super init];
    if (self) {
        _errors = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_errors release];
    [super dealloc];
}

- (void)addError:(NSError *)error
{
    [self.errors addObject:error];
}

- (ZincTask*) getTask
{
    if ([self.dependencies count] > 0) {
        return [self.dependencies objectAtIndex:0];
    }
    return nil;
}

- (BOOL) isValid
{
    return [self getTask] != nil;
}

- (BOOL) isSuccessful
{
    return [self isValid] && [self isFinished] && [[self allErrors] count] == 0;
}

- (NSArray*) allErrors
{
    NSArray* taskErrors = [[self getTask] allErrors];
    if ([taskErrors count] > 0) {
        return [self.errors arrayByAddingObjectsFromArray:taskErrors];
    }
    return self.errors;
}

@end
