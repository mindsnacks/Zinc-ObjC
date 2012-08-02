//
//  ZincEvent.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/6/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincEvent.h"
#import "ZincEvent+Private.h"

NSString *const kZincEventAttributesSourceKey = @"source";
NSString *const kZincEventAttributesURLKey = @"url";
NSString *const kZincEventAttributesPathKey = @"path";
NSString *const kZincEventAttributesBundleResourceKey = @"bundleResource";
NSString *const kZincEventAttributesArchiveResourceKey = @"archiveResource";
NSString *const kZincEventAttributesContextKey = @"context";

NSString *const kZincEventErrorNotification = @"ZincEventErrorNotification";
NSString *const kZincEventBundleUpdateNotification = @"ZincEventBundleUpdateNotification";
NSString *const kZincEventDeleteNotification = @"ZincEventDeleteNotification";
NSString *const kZincEventDownloadBeginNotification = @"ZincEventDownloadBeginNotification";
NSString *const kZincEventDownloadCompleteNotification = @"ZincEventDownloadCompleteNotification";
NSString *const kZincEventBundleCloneBeginNotification = @"ZincEventBundleCloneBeginNotification";
NSString *const kZincEventBundleCloneCompleteNotification = @"ZincEventBundleCloneCompleteNotification";
NSString *const kZincEventArchiveExtractBeginNotification = @"ZincEventArchiveExtractBeginNotification";
NSString *const kZincEventArchiveExtractCompleteNotification = @"ZincEventArchiveExtractCompleteNotification";
NSString *const kZincEventGarbageCollectionBeginNotification = @"ZincEventGarbageCollectionBeginNotification";
NSString *const kZincEventGarbageCollectionCompleteNotification = @"ZincEventGarbageCollectionCompleteNotification";

@interface ZincEvent ()
@property (nonatomic, assign, readwrite) ZincEventType type;
@property (nonatomic, retain, readwrite) NSDate* timestamp;
@property (nonatomic, retain, readwrite) NSDictionary* attributes;
@end

@implementation ZincEvent

@synthesize type = _type;
@synthesize timestamp = _timestamp;
@synthesize attributes = _attributes;

- (id) initWithType:(ZincEventType)type source:(id)source attributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        self.type = type;
        self.timestamp = [NSDate date];
        if (source != nil) {
            NSMutableDictionary *mutableAttributes = [[attributes mutableCopy] autorelease];;
            [mutableAttributes setObject:[source description] forKey:kZincEventAttributesSourceKey];
            self.attributes = mutableAttributes;
        } else {
            self.attributes = attributes;
        }
    }
    return self;
}

- (id) initWithType:(ZincEventType)type source:(id)source
{
    return [self initWithType:type source:source attributes:nil];
}

- (void)dealloc
{
    [_timestamp release];
    [_attributes release];
    [super dealloc];
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
                 k, [self.attributes objectForKey:k]];
    }
    return desc;
}

@end

#pragma mark -

@interface ZincErrorEvent ()
@property (nonatomic, retain, readwrite) NSError* error;
@end

@implementation ZincErrorEvent

@synthesize error = _error;

- (id) initWithError:(NSError*)error source:(id)source attributes:(NSDictionary*)attributes
{
    self = [super initWithType:ZincEventTypeError source:source attributes:attributes];
    if (self) {
        self.error = error;
    }
    return self;
}

- (void)dealloc
{
    [_error release];
    [super dealloc];
}

+ (id) eventWithError:(NSError*)error source:(id)source
{
    return [[[ZincErrorEvent alloc] initWithError:error source:source attributes:nil] autorelease];
}

+ (id) eventWithError:(NSError*)error source:(id)source attributes:(NSDictionary*)attributes;
{
    return [[[ZincErrorEvent alloc] initWithError:error source:source attributes:attributes] autorelease];
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
                 k, [self.attributes objectForKey:k]];
    }
    return desc;
}

@end

@implementation ZincDeleteEvent

+ (id) deleteEventForPath:(NSString*)path source:(id)source
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          path, kZincEventAttributesPathKey, nil];
    return [[[self alloc] initWithType:ZincEventTypeDelete source:source attributes:attr] autorelease];
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
    return [self.attributes objectForKey:kZincEventAttributesPathKey];
}

@end

@implementation ZincDownloadBeginEvent

+ (id) downloadBeginEventForURL:(NSURL*)url
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          url, kZincEventAttributesURLKey, nil];
    return [[[self alloc] initWithType:ZincEventTypeDownloadBegin source:nil attributes:attr] autorelease];

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
    return [self.attributes objectForKey:kZincEventAttributesURLKey];
}
                          
@end

@implementation ZincDownloadCompleteEvent

+ (id) downloadCompleteEventForURL:(NSURL*)url
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          url, kZincEventAttributesURLKey, nil];
    
    return [[[self alloc] initWithType:ZincEventTypeDownloadComplete source:nil attributes:attr] autorelease];
    
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
    return [self.attributes objectForKey:kZincEventAttributesURLKey];
}

@end

@implementation ZincBundleCloneBeginEvent

+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource source:(id)source context:(id)context
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          bundleResource, kZincEventAttributesBundleResourceKey,
                          context ?: [NSNull null], kZincEventAttributesContextKey, nil];
    
    return [[[self alloc] initWithType:ZincEventTypeBundleCloneBegin source:source attributes:attr] autorelease];
}

+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource context:(id)context
{
    return [self bundleCloneBeginEventForBundleResource:bundleResource source:nil context:context];
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
    return [self.attributes objectForKey:kZincEventAttributesBundleResourceKey];
}

- (id)context
{
    return [self.attributes objectForKey:kZincEventAttributesContextKey];
}

@end

@implementation ZincBundleCloneCompleteEvent

+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource source:(id)source context:(id)context;
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          bundleResource, kZincEventAttributesBundleResourceKey,
                          context ?: [NSNull null], kZincEventAttributesContextKey, nil];
    
    return [[[self alloc] initWithType:ZincEventTypeBundleCloneComplete source:source attributes:attr] autorelease];
}

+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource context:(id)context
{
    return [self bundleCloneCompleteEventForBundleResource:bundleResource source:nil context:context];
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
    return [self.attributes objectForKey:kZincEventAttributesBundleResourceKey];
}

- (id)context
{
    return [self.attributes objectForKey:kZincEventAttributesContextKey];
}

@end

@implementation ZincAchiveExtractBeginEvent

+ (id) archiveExtractBeginEventForResource:(NSURL*)archiveResource
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          archiveResource, kZincEventAttributesArchiveResourceKey, nil];
    return [[[self alloc] initWithType:ZincEventTypeArchiveExtractBegin source:nil attributes:attr] autorelease];
    
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
    return [self.attributes objectForKey:kZincEventAttributesArchiveResourceKey];
}

@end

@implementation ZincAchiveExtractCompleteEvent

+ (id) archiveExtractCompleteEventForResource:(NSURL*)archiveResource context:(id)context
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          archiveResource, kZincEventAttributesArchiveResourceKey,
                          context ?: [NSNull null], kZincEventAttributesContextKey, nil];
    return [[[self alloc] initWithType:ZincEventTypeArchiveExtractComplete source:nil attributes:attr] autorelease];
    
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
    return [self.attributes objectForKey:kZincEventAttributesArchiveResourceKey];
}

- (id)context
{
    return [self.attributes objectForKey:kZincEventAttributesContextKey];
}

@end


@implementation ZincGarbageCollectionBeginEvent

+ (id) event
{
    return [[[self alloc] initWithType:ZincEventTypeGarbageCollectBegin source:nil] autorelease];
}

+ (NSString*) name
{
    return @"GARBAGECOLLECT-BEGIN";
}

+ (NSString *)notificationName
{
    return kZincEventGarbageCollectionBeginNotification;
}

@end


@implementation ZincGarbageCollectionCompleteEvent

+ (id) event
{
    return [[[self alloc] initWithType:ZincEventTypeGarbageCollectComplete source:nil] autorelease];
}

+ (NSString*) name
{
    return @"GARBAGECOLLECT-COMPLETE";
}

+ (NSString *)notificationName
{
    return kZincEventGarbageCollectionCompleteNotification;
}
@end



