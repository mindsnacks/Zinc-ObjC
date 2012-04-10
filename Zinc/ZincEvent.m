//
//  ZincEvent.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/6/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincEvent.h"

NSString* const ZincEventNotification = @"ZincEventNotification";

NSString *const kZincEventAtributesURLKey = @"url";
NSString *const kZincEventAtributesPathKey = @"path";
NSString *const kZincEventAtributesBundleResourceKey = @"bundleResource";
NSString *const kZincEventAtributesArchiveResourceKey = @"archiveResource";
NSString *const kZincEventAtributesProgressKey = @"progress";
NSString *const kZincEventAtributesContextKey = @"context";

@interface ZincEvent ()
@property (nonatomic, assign, readwrite) ZincEventType type;
@property (nonatomic, retain, readwrite) id source;
@property (nonatomic, retain, readwrite) NSDate* timestamp;
@property (nonatomic, retain, readwrite) NSDictionary* attributes;
@end

@implementation ZincEvent

@synthesize type = _type;
@synthesize source = _source;
@synthesize timestamp = _timestamp;
@synthesize attributes = _attributes;

- (id) initWithType:(ZincEventType)type source:(id)source attributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        self.type = type;
        self.source = source;
        self.timestamp = [NSDate date];
        self.attributes = attributes;
    }
    return self;
}

- (id) initWithType:(ZincEventType)type source:(id)source
{
    return [self initWithType:type source:source attributes:nil];
}

- (void)dealloc
{
    self.source = nil;
    self.timestamp = nil;
    self.attributes = nil;
    [super dealloc];
}

+ (NSString*) name
{
    return @"EVENT";
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
    self.error = nil;
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
                          path, kZincEventAtributesPathKey, nil];
    return [[[self alloc] initWithType:ZincEventTypeDelete source:source attributes:attr] autorelease];
}

+ (NSString*) name
{
    return @"DELETE";
}

- (NSString*) path
{
    return [self.attributes objectForKey:kZincEventAtributesPathKey];
}

@end

@implementation ZincDownloadBeginEvent

+ (id) downloadBeginEventForURL:(NSURL*)url
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          url, kZincEventAtributesURLKey, nil];
    return [[[self alloc] initWithType:ZincEventTypeDownloadBegin source:nil attributes:attr] autorelease];

}
    
+ (NSString*) name
{
    return @"DOWNLOAD-BEGIN";
}

- (NSURL*) url
{
    return [self.attributes objectForKey:kZincEventAtributesURLKey];
}
                          
@end

@implementation ZincDownloadProgressEvent

+ (id)downloadProgressEventForURL:(NSURL *)url withProgress:(float)progress context:(id)context
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          url, kZincEventAtributesURLKey,
                          [NSNumber numberWithFloat:progress], kZincEventAtributesProgressKey,
                          context ?: [NSNull null], kZincEventAtributesContextKey, nil];
    
    return [[[self alloc] initWithType:ZincEventTypeDownloadProgress source:nil attributes:attr] autorelease];
}

+ (NSString*) name
{
    return @"DOWNLOAD-PROGRESSS";
}

- (NSURL*) url
{
    return [self.attributes objectForKey:kZincEventAtributesURLKey];
}

- (float)progress
{
    return [[self.attributes objectForKey:kZincEventAtributesProgressKey] floatValue];
}

- (id)context
{
    return [self.attributes objectForKey:kZincEventAtributesContextKey];
}

@end

@implementation ZincDownloadCompleteEvent

+ (id) downloadCompleteEventForURL:(NSURL*)url
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          url, kZincEventAtributesURLKey, nil];
    
    return [[[self alloc] initWithType:ZincEventTypeDownloadComplete source:nil attributes:attr] autorelease];
    
}

+ (NSString*) name
{
    return @"DOWNLOAD-COMPLETE";
}

- (NSURL*) url
{
    return [self.attributes objectForKey:kZincEventAtributesURLKey];
}

@end

@implementation ZincBundleCloneBeginEvent

+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          bundleResource, kZincEventAtributesBundleResourceKey, nil];
    
    return [[[self alloc] initWithType:ZincEventTypeBundleCloneBegin source:nil attributes:attr] autorelease];
}

+ (NSString*) name
{
    return @"CLONE-BEGIN";
}

- (NSURL*) bundleResource
{
    return [self.attributes objectForKey:kZincEventAtributesBundleResourceKey];
}

@end

@implementation ZincBundleCloneCompleteEvent

+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          bundleResource, kZincEventAtributesBundleResourceKey, nil];
    
    return [[[self alloc] initWithType:ZincEventTypeBundleCloneComplete source:nil attributes:attr] autorelease];
}

+ (NSString*) name
{
    return @"CLONE-COMPLETE";
}

- (NSURL*) bundleResource
{
    return [self.attributes objectForKey:kZincEventAtributesBundleResourceKey];
}

@end

@implementation ZincAchiveExtractBeginEvent

+ (id) archiveExtractBeginEventForResource:(NSURL*)archiveResource
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          archiveResource, kZincEventAtributesArchiveResourceKey, nil];
    return [[[self alloc] initWithType:ZincEventTypeArchiveExtractBegin source:nil attributes:attr] autorelease];
    
}

+ (NSString*) name
{
    return @"EXTRACT-BEGIN";
}

- (NSURL*) archiveResource
{
    return [self.attributes objectForKey:kZincEventAtributesArchiveResourceKey];
}

@end

@implementation ZincAchiveExtractCompleteEvent

+ (id) archiveExtractCompleteEventForResource:(NSURL*)archiveResource
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          archiveResource, kZincEventAtributesArchiveResourceKey, nil];
    return [[[self alloc] initWithType:ZincEventTypeArchiveExtractComplete source:nil attributes:attr] autorelease];
    
}

+ (NSString*) name
{
    return @"EXTRACT-COMPLETE";
}

- (NSURL*) archiveResource
{
    return [self.attributes objectForKey:kZincEventAtributesArchiveResourceKey];
}

@end
