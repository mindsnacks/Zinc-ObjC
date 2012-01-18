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
    ZincEventTypeDelete,
    ZincEventTypeDownloadBegin,
    ZincEventTypeDownloadComplete,
    ZincEventTypeBundleCloneBegin,
    ZincEventTypeBundleCloneComplete,
    ZincEventTypeArchiveExtractBegin,
    ZincEventTypeArchiveExtractComplete,
} ZincEventType;

#pragma mark Notifications

extern NSString* const ZincEventNotification;

@interface ZincEvent : NSObject

- (id) initWithType:(ZincEventType)type source:(id)source;
- (id) initWithType:(ZincEventType)type source:(id)source attributes:(NSDictionary*)attributes;;

+ (NSString*) name;

//+ (id) eventWithType:(ZincEventType)type source:(id)source
@property (nonatomic, assign, readonly) ZincEventType type;
@property (nonatomic, retain, readonly) id source;
@property (nonatomic, retain, readonly) NSDate* timestamp;
@property (nonatomic, retain, readonly) NSDictionary* attributes;
           
@end


@interface ZincErrorEvent : ZincEvent

- (id) initWithError:(NSError*)error source:(id)source attributes:(NSDictionary*)attributes;
@property (nonatomic, retain, readonly) NSError* error;

+ (id) eventWithError:(NSError*)error source:(id)source;
+ (id) eventWithError:(NSError*)error source:(id)source attributes:(NSDictionary*)attributes;

@end


@interface ZincDeleteEvent : ZincEvent 

+ (id) deleteEventForPath:(NSString*)path source:(id)source;
@property (readonly) NSString* path;

@end


@interface ZincDownloadBeginEvent : ZincEvent 

+ (id) downloadBeginEventForURL:(NSURL*)url;
@property (readonly) NSURL* url;

@end


@interface ZincDownloadCompleteEvent : ZincEvent 

+ (id) downloadCompleteEventForURL:(NSURL*)url;
@property (readonly) NSURL* url;

@end


@interface ZincBundleCloneBeginEvent : ZincEvent 

+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource;
@property (readonly) NSURL* bundleResource;

@end


@interface ZincBundleCloneCompleteEvent : ZincEvent 

+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource;
@property (readonly) NSURL* bundleResource;

@end


@interface ZincAchiveExtractBeginEvent : ZincEvent 

+ (id) archiveExtractBeginEventForResource:(NSURL*)archiveResource;
@property (readonly) NSURL* archiveResource;

@end


@interface ZincAchiveExtractCompleteEvent : ZincEvent 

+ (id) archiveExtractCompleteEventForResource:(NSURL*)archiveResource;
@property (readonly) NSURL* archiveResource;

@end
