//
//  ZincEvent.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/6/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ZincEventTypeError,
    ZincEventTypeBundleUpdate,
    ZincEventTypeCatalogUpdate,
} ZincEventType;

#pragma mark Notifications

extern NSString* const ZincEventNotification;

@interface ZincEvent : NSObject

- (id) initWithType:(ZincEventType)type source:(id)source;
@property (nonatomic, assign, readonly) ZincEventType type;
@property (nonatomic, retain, readonly) id source;
@property (nonatomic, retain, readonly) NSDate* timestamp;

@end

@interface ZincErrorEvent : ZincEvent

- (id) initWithError:(NSError*)error source:(id)source;
@property (nonatomic, retain, readonly) NSError* error;

+ (id) eventWithError:(NSError*)error source:(id)source;

@end