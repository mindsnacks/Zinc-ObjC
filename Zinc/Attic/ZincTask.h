//
//  ZincTask.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/5/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincClient.h"

@interface ZincTask : NSObject

- (id) initWithClient:(ZincClient*)client;
@property (nonatomic, assign, readonly) ZincClient* client;

@property (readonly) ZincTask* supertask;
@property (readonly) NSArray* subtasks;


- (void) start;
- (BOOL) isExecuting;
- (void) cancel;


- (NSString*) title;
- (double) progress;

- (NSString*) key;

@end
