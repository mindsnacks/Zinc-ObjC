//
//  ZincOperationQueueGroup+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/16/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

@class ZincOperationQueueGroupInfo;

#import "ZincOperationQueueGroup.h"

@interface ZincOperationQueueGroup ()

- (NSOperationQueue*) getQueueForClass:(Class)cls;

- (NSArray*) getAllBarrierOperations;

- (NSArray*) getDependenciesForOperationWithInfo:(ZincOperationQueueGroupInfo*)info;


@end