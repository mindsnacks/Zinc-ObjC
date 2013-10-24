//
//  ZincOperationQueueGroup.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZincOperationQueueGroup : NSObject

/** @discussion Designated initializer.
    @note all ZincOperationQueueGroups start suspended.
 */
- (id)init;

- (void) setMaxConcurrentOperationCount:(NSInteger)cnt forClass:(Class)theClass;
- (void) setIsBarrierOperationForClass:(Class)theClass;

- (void) addOperation:(NSOperation*)operation;

- (void) setSuspended:(BOOL)b;
- (BOOL) isSuspended;

- (void) suspendAndWaitForExecutingOperationsToComplete;

@end
