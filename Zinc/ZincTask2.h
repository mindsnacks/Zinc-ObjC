//
//  ZincTask2.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZincClient;
@class ZincEvent;

@interface ZincTask2 : NSOperation

- (id) initWithClient:(ZincClient*)client;
@property (nonatomic, assign, readonly) ZincClient* client;

@property (assign) ZincTask2* supertask;
@property (readonly) NSArray* subtasks;

@property (readonly, retain) NSString* title;
- (double) progress;

- (NSString*) key;

@end


#pragma mark Private

@interface ZincTask2 ()

@property (readwrite, retain) NSString* title;

@property (retain) NSMutableArray* suboperations;
- (void) addOperation:(NSOperation*)operation;
//- (void) waitForSuboperations;

@property (readonly) NSArray* events;
- (void) addEvent:(ZincEvent*)event;

@property (assign) BOOL finishedSuccessfully;

@end
