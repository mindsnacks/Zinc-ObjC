//
//  ZincOperationQueueGroup.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZincOperationQueueGroup : NSObject

- (void) setMaxConcurrentOperationCount:(NSInteger)cnt forClass:(Class)theClass;

- (void) addOperation:(NSOperation*)operation;

- (NSOperationQueue*) getQueueForClass:(Class)theClass;

- (void)setSuspended:(BOOL)b;
- (BOOL)isSuspended;

@end
