//
//  ZincTaskStep.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZincTask;

@interface ZincTaskStep : NSObject

- (id) initWithTask:(ZincTask*)task title:(NSString*)title executionBlock:(dispatch_block_t)block;

@end
