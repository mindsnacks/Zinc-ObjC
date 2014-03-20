//
//  ZincTaskRef.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/29/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperation.h"

@class ZincTask;

/**
 `ZincTaskRef`

 This class is part of the *Zinc Public API*.
 
 `ZincTaskRef` objects, or just "task refs" provide a way to wait for, or be
 notified of completion of a `ZincTask`. `ZincTaskRefs` are `NSOperations`
 themselves which at the target task as a dependency. 
*/
@interface ZincTaskRef : ZincOperation

/**
 Create a new `ZincTaskRef` for a `ZincTask`
 
 @param task the task
 @return a new task reference
 */
+ (ZincTaskRef*) taskRefForTask:(ZincTask*)task;

/**
 @todo Could this be removed if constructor checked for nil task?
 */
- (BOOL) isValid;

/**
 @return `YES` if task has completed successfully, `NO` otherwise.
 */
- (BOOL) isSuccessful;

/**
 @return `YES` if the task was not necessary, `NO` otherwise.
 */
- (BOOL) bundleWasAlreadyAvailable;

/**
 @return All errors from the task
 */
- (NSArray*) allErrors;

@end
