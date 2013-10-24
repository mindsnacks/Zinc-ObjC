//
//  ZincTask+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"
#import "ZincOperation+Private.h"

@class ZincEvent;

@interface ZincTask ()

// Designated Initializer
- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input;
- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource;

- (ZincTask*) queueChildTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor;
- (ZincTask*) queueChildTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input;

/* Currently for network ops ONLY. Consider refactoring to clean up the API */
- (void) queueChildOperation:(NSOperation*)operation;

/* just the events logged on this task */
@property (readonly) NSArray* events;

- (void) addEvent:(ZincEvent*)event;

@property (readwrite, copy) NSString* title;

@property (assign) BOOL finishedSuccessfully;

+ (NSString*) taskMethod;
+ (ZincTaskDescriptor*) taskDescriptorForResource:(NSURL*)resource;

- (void)setShouldExecuteAsBackgroundTask;


/**
 * @discussion Called to update isReady periodically. Default implementation just fires willChange/didChange on isReady key to force isReady to be called again. Subclasses may override.
 */
- (void) updateReadiness;

@end
