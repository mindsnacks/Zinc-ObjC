//
//  ZincTaskRequest.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/17/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZincTaskDescriptor;

@interface ZincTaskRequest : NSObject

@property (nonatomic, strong) ZincTaskDescriptor* taskDescriptor;
@property (nonatomic, strong) id input;
@property (nonatomic, strong) NSOperation* parent;
@property (nonatomic, strong) NSArray* dependencies;

/**
 * Defaults to 'NSOperationQueuePriorityNormal'
 */
@property (nonatomic) NSOperationQueuePriority priority;

@end
