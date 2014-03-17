//
//  ZincTaskRef.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/29/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTaskRef+Private.h"

#import "ZincTask.h"

@interface ZincTaskRef ()
{
    BOOL _bundleWasAlreadyAvailable;
}
@property (nonatomic, strong) NSMutableArray* errors;
@end

@implementation ZincTaskRef

- (id)init
{
    self = [super init];
    if (self) {
        _errors = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (ZincTaskRef*) taskRefForTask:(ZincTask*)task
{
    ZincTaskRef* ref = [[ZincTaskRef alloc] init];
    [ref addDependency:task];
    return ref;
}


- (void)addError:(NSError *)error
{
    [self.errors addObject:error];
}

- (void) setBundleWasAlreadyAvailable
{
    _bundleWasAlreadyAvailable = YES;
}

- (ZincTask*) getTask
{
    if ([self.dependencies count] > 0) {
        return (self.dependencies)[0];
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

- (BOOL) bundleWasAlreadyAvailable {
    return _bundleWasAlreadyAvailable;
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
