//
//  ZincTaskOperation.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZincTask;
@class ZincEvent;

//@protocol ZincOperationDispatch;

@interface ZincTaskOperation : NSOperation

- (id) initWithTask:(ZincTask*)task;/// dispatch:(id<ZincOperationDispatch>)dispatch;
@property (nonatomic, retain, readonly) ZincTask* task;

//- (NSSet*) suboperations;

- (void) completeWithSuccess:(BOOL)yn;

- (void) addEvent:(ZincEvent*)event;

@end
