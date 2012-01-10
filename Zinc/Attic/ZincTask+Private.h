//
//  ZincTask+Private.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/6/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"

@class ZincEvent;

@interface ZincTask ()

- (NSOperation*) operation;

- (ZincTask*) addSubtask:(ZincTask*)subtask;

@end