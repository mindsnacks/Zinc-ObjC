//
//  ZincTask.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@property (assign) ZincTask* supertask;
@property (readonly) NSArray* subtasks;

@property (readonly) NSArray* events;

- (double) progress;

@end

#pragma mark Private

@interface ZincTask ()

- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource;
- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input;

@property (retain) NSMutableArray* suboperations;
- (void) addOperation:(NSOperation*)operation;
//- (void) waitForSuboperations;

- (void) addEvent:(ZincEvent*)event;

@property (readwrite, retain) NSString* title;

@property (assign) BOOL finishedSuccessfully;

+ (NSString*) taskMethod;
+ (ZincTaskDescriptor*) taskDescriptorForResource:(NSURL*)resource;
- (ZincTaskDescriptor*) taskDescriptor;

@end
