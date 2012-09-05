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
    ZincEventTypeGarbageCollectBegin,
    ZincEventTypeGarbageCollectComplete,
} ZincEventType;

extern NSString *const kZincEventAttributesSourceKey;
extern NSString *const kZincEventAttributesURLKey;
extern NSString *const kZincEventAttributesPathKey;
extern NSString *const kZincEventAttributesBundleResourceKey;
extern NSString *const kZincEventAttributesArchiveResourceKey;
extern NSString *const kZincEventAttributesContextKey;

#pragma mark Notifications

extern NSString *const kZincEventErrorNotification;
extern NSString *const kZincEventBundleUpdateNotification;
extern NSString *const kZincEventDeleteNotification;
extern NSString *const kZincEventDownloadBeginNotification;
extern NSString *const kZincEventDownloadCompleteNotification;
extern NSString *const kZincEventBundleCloneBeginNotification;
extern NSString *const kZincEventBundleCloneCompleteNotification;
extern NSString *const kZincEventArchiveExtractBeginNotification;
extern NSString *const kZincEventArchiveExtractCompleteNotification;
extern NSString *const kZincEventGarbageCollectionBeginNotification;
extern NSString *const kZincEventGarbageCollectionCompleteNotification;

@interface ZincEvent : NSObject

- (id) initWithType:(ZincEventType)type source:(id)source;
- (id) initWithType:(ZincEventType)type source:(id)source attributes:(NSDictionary*)attributes;;

+ (NSString*) name;

@property (nonatomic, assign, readonly) ZincEventType type;
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

+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource context:(id)context;
+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource source:(id)source context:(id)context;
@property (readonly) NSURL* bundleResource;
@property (readonly) id context;

@end


@interface ZincBundleCloneCompleteEvent : ZincEvent 

+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource source:(id)source context:(id)context;
+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource context:(id)context;
@property (readonly) NSURL* bundleResource;
@property (readonly) id context;

@end


@interface ZincAchiveExtractBeginEvent : ZincEvent 

+ (id) archiveExtractBeginEventForResource:(NSURL*)archiveResource;
@property (readonly) NSURL* archiveResource;

@end


@interface ZincAchiveExtractCompleteEvent : ZincEvent 

+ (id) archiveExtractCompleteEventForResource:(NSURL*)archiveResource context:(id)context;
@property (readonly) NSURL* archiveResource;
@property (readonly) id context;

@end


@interface ZincGarbageCollectionBeginEvent : ZincEvent

+ (id) event;

@end


@interface ZincGarbageCollectionCompleteEvent : ZincEvent

+ (id) event;

@end
