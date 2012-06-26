//
//  ZincTask.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"

@class ZincRepo;
@class ZincEvent;
@class ZincTaskDescriptor;

@interface ZincTask : NSOperation

+ (id) taskWithDescriptor:(ZincTaskDescriptor*)taskDesc repo:(ZincRepo*)repo;
+ (id) taskWithDescriptor:(ZincTaskDescriptor*)taskDesc repo:(ZincRepo*)repo input:(id)input;

@property (nonatomic, assign, readonly) ZincRepo* repo;
@property (nonatomic, retain, readonly) NSURL* resource;
@property (nonatomic, retain, readonly) id input;

@property (readonly, retain) NSString* title;

@property (readonly) NSArray* subtasks;

/* just the events logged on this task */
@property (readonly) NSArray* events;

/* all events including events from subtasks */
- (NSArray*) getAllEvents;

- (NSInteger) currentProgressValue;
- (NSInteger) maxProgressValue;

- (double) progress;

@end

#pragma mark Private

@interface ZincTask ()

// Designated Initializer
- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input;
- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource;

- (ZincTask*) queueSubtaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor;
- (ZincTask*) queueSubtaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input;

/* Current for network ops ONLY. Consider refactoring to clean up the API */
- (void) addOperation:(NSOperation*)operation;

//- (void) waitForSuboperations;

- (void) addEvent:(ZincEvent*)event;

@property (readwrite, retain) NSString* title;

@property (assign) BOOL finishedSuccessfully;

+ (NSString*) taskMethod;
+ (ZincTaskDescriptor*) taskDescriptorForResource:(NSURL*)resource;
- (ZincTaskDescriptor*) taskDescriptor;

@end
