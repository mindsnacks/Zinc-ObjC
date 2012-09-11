//
//  ZincTask.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"
#import "ZincOperation.h"

@class ZincRepo;
@class ZincTaskDescriptor;

@interface ZincTask : ZincOperation

+ (id) taskWithDescriptor:(ZincTaskDescriptor*)taskDesc repo:(ZincRepo*)repo;
+ (id) taskWithDescriptor:(ZincTaskDescriptor*)taskDesc repo:(ZincRepo*)repo input:(id)input;

- (ZincTaskDescriptor*) taskDescriptor;

@property (nonatomic, assign, readonly) ZincRepo* repo;
@property (nonatomic, retain, readonly) NSURL* resource;
@property (nonatomic, retain, readonly) id input;

@property (readonly, retain) NSString* title;

@property (readonly) NSArray* subtasks;

/* all events including events from subtasks */
- (NSArray*) allEvents;

/* all errors that occurred including errors from subtasks */
- (NSArray*) allErrors;

@end
