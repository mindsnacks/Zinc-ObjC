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

@interface ZincTask : NSOperation

- (id) initWithRepo:(ZincRepo*)repo;
@property (nonatomic, assign, readonly) ZincRepo* repo;

@property (assign) ZincTask* supertask;
@property (readonly) NSArray* subtasks;

@property (readonly, retain) NSString* title;
- (double) progress;

- (NSString*) key;

@end


#pragma mark Private

@interface ZincTask ()

@property (readwrite, retain) NSString* title;

@property (retain) NSMutableArray* suboperations;
- (void) addOperation:(NSOperation*)operation;
//- (void) waitForSuboperations;

@property (readonly) NSArray* events;
- (void) addEvent:(ZincEvent*)event;

@property (assign) BOOL finishedSuccessfully;

@end
