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

//@property (nonatomic, readonly, assign) ZincTask* supertask;
//@property (nonatomic, readonly) NSArray* subtasks;

- (id) initWithClient:(ZincClient*)client;

@property (nonatomic, readonly) NSArray* events;

//- (BOOL) isExecuting;

- (BOOL) wasCompletedSuccessfully;

- (void) run;

- (double) progress;

- (NSString*) descriptor;

@end
