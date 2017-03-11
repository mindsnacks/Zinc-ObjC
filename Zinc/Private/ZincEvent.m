//
//  ZincEvent.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/6/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincEvent+Private.h"

NSString *const kZincEventAttributesSourceKey = @"source";
NSString *const kZincEventAttributesURLKey = @"url";
NSString *const kZincEventAttributesSizeKey = @"size";
NSString *const kZincEventAttributesPathKey = @"path";
NSString *const kZincEventAttributesBundleResourceKey = @"bundleResource";
NSString *const kZincEventAttributesArchiveResourceKey = @"archiveResource";
NSString *const kZincEventAttributesContextKey = @"context";
NSString *const kZincEventAttributesCloneSuccessKey = @"success";
NSString *const kZincEventAttributesActionKey = @"action";

NSString *const kZincEventErrorNotification = @"ZincEventErrorNotification";
NSString *const kZincEventBundleUpdateNotification = @"ZincEventBundleUpdateNotification";
NSString *const kZincEventDeleteNotification = @"ZincEventDeleteNotification";
NSString *const kZincEventDownloadBeginNotification = @"ZincEventDownloadBeginNotification";
NSString *const kZincEventDownloadCompleteNotification = @"ZincEventDownloadCompleteNotification";
NSString *const kZincEventBundleCloneBeginNotification = @"ZincEventBundleCloneBeginNotification";
NSString *const kZincEventBundleCloneCompleteNotification = @"ZincEventBundleCloneCompleteNotification";
NSString *const kZincEventArchiveExtractBeginNotification = @"ZincEventArchiveExtractBeginNotification";
NSString *const kZincEventArchiveExtractCompleteNotification = @"ZincEventArchiveExtractCompleteNotification";
NSString *const kZincEventMaintenanceBeginNotification = @"ZincEventMaintenanceionBeginNotification";
NSString *const kZincEventMaintenanceionCompleteNotification = @"ZincEventMaintenanceionCompleteNotification";
NSString *const kZincEventCatalogUpdatedNotification = @"kZincEventCatalogUpdatedNotification";


@interface ZincEvent ()
@property (nonatomic, assign, readwrite) ZincEventType type;
@property (nonatomic, copy, readwrite) NSDate* timestamp;
@property (nonatomic, copy, readwrite) NSDictionary* attributes;
@end


@implementation ZincEvent

- (id) initWithType:(ZincEventType)type source:(NSDictionary*)source attributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        self.type = type;
        self.timestamp = [NSDate date];
        if (source != nil) {
            NSMutableDictionary *mutableAttributes = [attributes mutableCopy];;
            mutableAttributes[kZincEventAttributesSourceKey] = [source description];
            self.attributes = mutableAttributes;
        } else {
            self.attributes = attributes;
        }
    }
    return self;
}

- (id) initWithType:(ZincEventType)type source:(NSDictionary*)source
{
    return [self initWithType:type source:source attributes:nil];
}


+ (NSString*) name
{
    return @"EVENT";
}

+ (NSString *)notificationName
{
    return nil;
}

- (NSString*) description
{
    NSString* desc = [NSString stringWithFormat:@"%@:", [[self class] name]];
    for (NSString* k in self.attributes) {
        desc  = [desc stringByAppendingFormat:@" '%@'='%@'",
                 k, (self.attributes)[k]];
    }
    return desc;
}

@end

#pragma mark -

@implementation ZincErrorEvent

- (id) initWithError:(NSError*)error source:(NSDictionary*)source attributes:(NSDictionary*)attributes
{
    self = [super initWithType:ZincEventTypeError source:source attributes:attributes];
    if (self) {
        self.error = error;
    }
    return self;
}


+ (id) eventWithError:(NSError*)error source:(NSDictionary*)source
{
    return [[ZincErrorEvent alloc] initWithError:error source:source attributes:nil];
}

+ (id) eventWithError:(NSError*)error source:(NSDictionary*)source attributes:(NSDictionary*)attributes;
{
    return [[ZincErrorEvent alloc] initWithError:error source:source attributes:attributes];
}

+ (NSString*) name
{
    return @"ERROR";
}

+ (NSString *)notificationName
{
    return kZincEventErrorNotification;
}

- (NSString*) description
{
    NSString* desc = [NSString stringWithFormat:@"%@: %@ ", [[self class] name], self.error];
    for (NSString* k in self.attributes) {
        desc  = [desc stringByAppendingFormat:@" '%@'='%@'",
                 k, (self.attributes)[k]];
    }
    return desc;
}

@end

@implementation ZincDeleteEvent

+ (id) deleteEventForPath:(NSString*)path source:(NSDictionary*)source
{
    NSDictionary* attr = @{kZincEventAttributesPathKey: path};
    return [[self alloc] initWithType:ZincEventTypeDelete source:source attributes:attr];
}

+ (NSString*) name
{
    return @"DELETE";
}

+ (NSString *)notificationName
{
    return kZincEventDeleteNotification;
}

- (NSString*) path
{
    return (self.attributes)[kZincEventAttributesPathKey];
}

@end

@implementation ZincDownloadBeginEvent

+ (id) downloadBeginEventForURL:(NSURL*)url
{
    NSDictionary* attr = @{kZincEventAttributesURLKey: url};
    return [[self alloc] initWithType:ZincEventTypeDownloadBegin source:ZINC_EVENT_SRC() attributes:attr];

}
    
+ (NSString*) name
{
    return @"DOWNLOAD-BEGIN";
}

+ (NSString *)notificationName
{
    return kZincEventDownloadBeginNotification;
}

- (NSURL*) url
{
    return (self.attributes)[kZincEventAttributesURLKey];
}
                          
@end

@implementation ZincDownloadCompleteEvent

+ (id) downloadCompleteEventForURL:(NSURL*)url size:(long long)size
{
    NSDictionary* attr = @{kZincEventAttributesURLKey: url,
                          kZincEventAttributesSizeKey: @(size)};
    
    return [[self alloc] initWithType:ZincEventTypeDownloadComplete source:ZINC_EVENT_SRC() attributes:attr];
    
}

+ (NSString*) name
{
    return @"DOWNLOAD-COMPLETE";
}

+ (NSString *)notificationName
{
    return kZincEventDownloadCompleteNotification;
}

- (NSURL*) url
{
    return (self.attributes)[kZincEventAttributesURLKey];
}

- (long long) size
{
    return [(self.attributes)[kZincEventAttributesSizeKey] longLongValue];
}

@end

@implementation ZincBundleCloneBeginEvent

+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource source:(NSDictionary*)source context:(id)context
{
    NSDictionary* attr = @{kZincEventAttributesBundleResourceKey: bundleResource,
                          kZincEventAttributesContextKey: context ?: [NSNull null]};
    
    return [[self alloc] initWithType:ZincEventTypeBundleCloneBegin source:source attributes:attr];
}

+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource context:(id)context
{
    return [self bundleCloneBeginEventForBundleResource:bundleResource source:ZINC_EVENT_SRC() context:context];
}

+ (NSString*) name
{
    return @"CLONE-BEGIN";
}

+ (NSString *)notificationName
{
    return kZincEventBundleCloneBeginNotification;
}

- (NSURL*) bundleResource
{
    return (self.attributes)[kZincEventAttributesBundleResourceKey];
}

- (id)context
{
    return (self.attributes)[kZincEventAttributesContextKey];
}

@end

@implementation ZincBundleCloneCompleteEvent

+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource source:(NSDictionary*)source context:(id)context success:(BOOL)success
{
    NSDictionary* attr = @{kZincEventAttributesBundleResourceKey: bundleResource,
                          kZincEventAttributesContextKey: context ?: [NSNull null],
                          kZincEventAttributesCloneSuccessKey: @(success)};
    
    return [[self alloc] initWithType:ZincEventTypeBundleCloneComplete source:source attributes:attr];
}

+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource context:(id)context success:(BOOL)success
{
    return [self bundleCloneCompleteEventForBundleResource:bundleResource source:ZINC_EVENT_SRC() context:context success:success];
}

+ (NSString*) name
{
    return @"CLONE-COMPLETE";
}

+ (NSString *)notificationName
{
    return kZincEventBundleCloneCompleteNotification;
}

- (NSURL*) bundleResource
{
    return (self.attributes)[kZincEventAttributesBundleResourceKey];
}

- (id)context
{
    return (self.attributes)[kZincEventAttributesContextKey];
}

@end

@implementation ZincArchiveExtractBeginEvent

+ (id) archiveExtractBeginEventForResource:(NSURL*)archiveResource
{
    NSDictionary* attr = @{kZincEventAttributesArchiveResourceKey: archiveResource};
    return [[self alloc] initWithType:ZincEventTypeArchiveExtractBegin source:ZINC_EVENT_SRC() attributes:attr];
    
}

+ (NSString*) name
{
    return @"EXTRACT-BEGIN";
}

+ (NSString *)notificationName
{
    return kZincEventArchiveExtractBeginNotification;
}

- (NSURL*) archiveResource
{
    return (self.attributes)[kZincEventAttributesArchiveResourceKey];
}

@end

@implementation ZincArchiveExtractCompleteEvent

+ (id) archiveExtractCompleteEventForResource:(NSURL*)archiveResource context:(id)context
{
    NSDictionary* attr = @{kZincEventAttributesArchiveResourceKey: archiveResource,
                          kZincEventAttributesContextKey: context ?: [NSNull null]};
    return [[self alloc] initWithType:ZincEventTypeArchiveExtractComplete source:ZINC_EVENT_SRC() attributes:attr];
    
}

+ (NSString*) name
{
    return @"EXTRACT-COMPLETE";
}

+ (NSString *)notificationName
{
    return kZincEventArchiveExtractCompleteNotification;
}

- (NSURL*) archiveResource
{
    return (self.attributes)[kZincEventAttributesArchiveResourceKey];
}

- (id)context
{
    return (self.attributes)[kZincEventAttributesContextKey];
}

@end


@implementation ZincMaintenanceBeginEvent

+ (id) maintenanceEventWithAction:(NSString*)category;
{
    NSDictionary* attr = @{kZincEventAttributesActionKey: category};
    return [[self alloc] initWithType:ZincEventTypeMaintenanceBegin source:ZINC_EVENT_SRC() attributes:attr];
}

+ (NSString*) name
{
    return @"MAINTENANCE-BEGIN";
}

+ (NSString *)notificationName
{
    return kZincEventMaintenanceBeginNotification;
}

- (NSString*) action
{
    return self.attributes[kZincEventAttributesActionKey];
}

@end


@implementation ZincMaintenanceCompleteEvent

+ (id) maintenanceEventWithAction:(NSString*)category
{
    NSDictionary* attr = @{kZincEventAttributesActionKey: category};
    return [[self alloc] initWithType:ZincEventTypeMaintenanceComplete source:ZINC_EVENT_SRC() attributes:attr];
}

+ (NSString*) name
{
    return @"MAINTENANCE-COMPLETE";
}

+ (NSString *)notificationName
{
    return kZincEventMaintenanceionCompleteNotification;
}

- (NSString*) action
{
    return self.attributes[kZincEventAttributesActionKey];
}

@end


@implementation ZincCatalogUpdatedEvent

+ (id)catalogUpdatedEventWithURL:(NSURL*)catalogURL source:(NSDictionary*)source
{
    NSDictionary* attr = @{kZincEventAttributesURLKey: catalogURL};
    return [[self alloc] initWithType:ZincEventTypeCatalogUpdate source:source attributes:attr];
}


- (NSURL*)catalogURL
{
    return (self.attributes)[kZincEventAttributesURLKey];
}

+ (NSString*)name
{
    return @"CATALOG-UPDATED";
}

+ (NSString *)notificationName
{
    return kZincEventMaintenanceionCompleteNotification;
}

@end



