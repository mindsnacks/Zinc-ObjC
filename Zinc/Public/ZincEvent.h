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

#pragma mark -

@interface ZincEvent : NSObject

+ (NSString*) name;

@property (nonatomic, assign, readonly) ZincEventType type;
@property (nonatomic, copy, readonly) NSDate* timestamp;
@property (nonatomic, copy, readonly) NSDictionary* attributes;

@end

@interface ZincErrorEvent : ZincEvent

@property (readonly, strong) NSError* error;

@end


@interface ZincDeleteEvent : ZincEvent

@property (readonly) NSString* path;

@end


@interface ZincDownloadBeginEvent : ZincEvent 

@property (readonly) NSURL* url;

@end


@interface ZincDownloadCompleteEvent : ZincEvent 

@property (readonly) NSURL* url;
@property (readonly) long long size;

@end


@interface ZincBundleCloneBeginEvent : ZincEvent 

@property (readonly) NSURL* bundleResource;
@property (readonly) id context;

@end


@interface ZincBundleCloneCompleteEvent : ZincEvent 

@property (readonly) NSURL* bundleResource;
@property (readonly) id context;

@end


@interface ZincArchiveExtractBeginEvent : ZincEvent 

@property (readonly) NSURL* archiveResource;

@end


@interface ZincArchiveExtractCompleteEvent : ZincEvent 

@property (readonly) NSURL* archiveResource;
@property (readonly) id context;

@end


@interface ZincMaintenanceBeginEvent : ZincEvent

@property (readonly) NSString* action;

@end


@interface ZincMaintenanceCompleteEvent : ZincEvent

@property (readonly) NSString* action;

@end


@interface ZincCatalogUpdatedEvent: ZincEvent

@property (readonly) NSURL* bundleResource;

@end
