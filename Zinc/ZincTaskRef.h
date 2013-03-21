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

/**
 @discussion Returns YES if successfully attached to a task. NO otherwise.
 */
- (BOOL) isValid;

- (BOOL) isSuccessful;

- (NSArray*) allErrors;

@end
