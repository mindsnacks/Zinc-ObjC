//
//  ZincTask+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"

@class ZincEvent;

@interface ZincTask ()

// Designated Initializer
- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input;
- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource;

- (ZincTask*) queueSubtaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor;
- (ZincTask*) queueSubtaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input;

/* Currently for network ops ONLY. Consider refactoring to clean up the API */
- (void) addOperation:(NSOperation*)operation;

/* just the events logged on this task */
@property (readonly) NSArray* events;

- (void) addEvent:(ZincEvent*)event;

@property (readwrite, retain) NSString* title;

@property (assign) BOOL finishedSuccessfully;

+ (NSString*) taskMethod;
+ (ZincTaskDescriptor*) taskDescriptorForResource:(NSURL*)resource;

#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (void)setShouldExecuteAsBackgroundTask;
#endif


/**
 * @discussion Called to update isReady periodically. Default implementation just fires willChange/didChange on isReady key to force isReady to be called again. Subclasses may override.
 */
- (void) updateReadiness;

@end
