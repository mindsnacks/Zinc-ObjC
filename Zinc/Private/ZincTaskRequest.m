//
//  ZincTaskRequest.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/17/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincTaskRequest.h"

@implementation ZincTaskRequest

- (id)init
{
    self = [super init];
    if (self) {
        self.priority = NSOperationQueuePriorityNormal;
    }
    return self;
}

@end
