//
//  ZincEvent.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/6/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark Event Types

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
    ZincEventTypeMaintenanceBegin,
    ZincEventTypeMaintenanceComplete,
} ZincEventType;


#pragma mark Attributes

extern NSString *const kZincEventAttributesSourceKey;
extern NSString *const kZincEventAttributesURLKey;
extern NSString *const kZincEventAttributesSizeKey;
extern NSString *const kZincEventAttributesPathKey;
extern NSString *const kZincEventAttributesBundleResourceKey;
extern NSString *const kZincEventAttributesArchiveResourceKey;
extern NSString *const kZincEventAttributesContextKey;
extern NSString *const kZincEventAttributesCloneSuccessKey;
extern NSString *const kZincEventAttributesActionKey;


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
extern NSString *const kZincEventMaintenanceBeginNotification;
extern NSString *const kZincEventMaintenanceionCompleteNotification;


#pragma mark Event Source Utils

#define ZINC_EVENT_SRC() _ZincEventSrcMake(self, __PRETTY_FUNCTION__, __LINE__)

static inline NSDictionary* _ZincEventSrcMake(id obj, char const * func, int line)
{
    return @{
             @"object": [NSString stringWithFormat:@"%p", obj],
             @"class": NSStringFromClass([obj class]),
             @"function": [NSString stringWithFormat:@"%s", func],
             @"line": [NSString stringWithFormat:@"%d", line],
             };
}


#pragma mark -

@interface ZincEvent : NSObject

- (id) initWithType:(ZincEventType)type source:(NSDictionary*)source;
- (id) initWithType:(ZincEventType)type source:(NSDictionary*)source attributes:(NSDictionary*)attributes;;

+ (NSString*) name;

@property (nonatomic, assign, readonly) ZincEventType type;
@property (nonatomic, copy, readonly) NSDate* timestamp;
@property (nonatomic, copy, readonly) NSDictionary* attributes;

@end

@interface ZincErrorEvent : ZincEvent

- (id) initWithError:(NSError*)error source:(NSDictionary*)source attributes:(NSDictionary*)attributes;
@property (nonatomic, strong, readonly) NSError* error;

+ (id) eventWithError:(NSError*)error source:(NSDictionary*)source;
+ (id) eventWithError:(NSError*)error source:(NSDictionary*)source attributes:(NSDictionary*)attributes;

@end


@interface ZincDeleteEvent : ZincEvent 

+ (id) deleteEventForPath:(NSString*)path source:(NSDictionary*)source;
@property (readonly) NSString* path;

@end


@interface ZincDownloadBeginEvent : ZincEvent 

+ (id) downloadBeginEventForURL:(NSURL*)url;
@property (readonly) NSURL* url;

@end


@interface ZincDownloadCompleteEvent : ZincEvent 

+ (id) downloadCompleteEventForURL:(NSURL*)url size:(NSInteger)size;
@property (readonly) NSURL* url;
@property (readonly) NSInteger size;

@end


@interface ZincBundleCloneBeginEvent : ZincEvent 

+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource context:(id)context;
+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource source:(NSDictionary*)source context:(id)context;
@property (readonly) NSURL* bundleResource;
@property (readonly) id context;

@end


@interface ZincBundleCloneCompleteEvent : ZincEvent 

+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource source:(NSDictionary*)source context:(id)context success:(BOOL)success;
+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource context:(id)context success:(BOOL)success;
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


@interface ZincMaintenanceBeginEvent : ZincEvent

+ (id) maintenanceEventWithAction:(NSString*)category;
@property (readonly) NSString* action;

@end


@interface ZincMaintenanceCompleteEvent : ZincEvent

+ (id) maintenanceEventWithAction:(NSString*)action;
@property (readonly) NSString* action;

@end
