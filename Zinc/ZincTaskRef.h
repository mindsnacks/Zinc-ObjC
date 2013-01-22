//
//  ZincTaskRef.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/29/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperation.h"

@class ZincTask;

@interface ZincTaskRef : ZincOperation

+ (ZincTaskRef*) taskRefForTask:(ZincTask*)task;

- (BOOL) isValid;

- (BOOL) isSuccessful;

- (NSArray*) allErrors;

#pragma mark Private

- (void) addError:(NSError*)error;

@end
