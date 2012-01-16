//
//  ZincEvent.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/6/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincEvent.h"

NSString* const ZincEventNotification = @"ZincEventNotification";

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

@end


@implementation ZincDeleteEvent

+ (id) deleteEventForPath:(NSString*)path source:(id)source
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          path, @"path", nil];
    return [[[self alloc] initWithType:ZincEventTypeDelete source:source attributes:attr] autorelease];
}

+ (NSString*) name
{
    return @"DELETE";
}

- (NSString*) path
{
    return [self.attributes objectForKey:@"path"];
    
}

@end



@implementation ZincDownloadBeginEvent

+ (id) downloadBeginEventForURL:(NSURL*)url
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          url, @"url", nil];
    return [[[self alloc] initWithType:ZincEventTypeDownloadBegin source:nil attributes:attr] autorelease];

}
    
+ (NSString*) name
{
    return @"DOWNLOAD-BEGIN";
}

- (NSURL*) url
{
    return [self.attributes objectForKey:@"url"];
}
                          
@end


@implementation ZincDownloadCompleteEvent

+ (id) downloadCompleteEventForURL:(NSURL*)url
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          url, @"url", nil];
    return [[[self alloc] initWithType:ZincEventTypeDownloadComplete source:nil attributes:attr] autorelease];
    
}

+ (NSString*) name
{
    return @"DOWNLOAD-COMPLETE";
}

- (NSURL*) url
{
    return [self.attributes objectForKey:@"url"];
}

@end


@implementation ZincBundleCloneBeginEvent

+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          bundleResource, @"bundleResource", nil];
    return [[[self alloc] initWithType:ZincEventTypeBundleCloneBegin source:nil attributes:attr] autorelease];
    
}

+ (NSString*) name
{
    return @"CLONE-BEGIN";
}

- (NSURL*) bundleResource
{
    return [self.attributes objectForKey:@"bundleResource"];
}

@end


@implementation ZincBundleCloneCompleteEvent

+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource
{
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          bundleResource, @"bundleResource", nil];
    return [[[self alloc] initWithType:ZincEventTypeBundleCloneComplete source:nil attributes:attr] autorelease];
    
}

+ (NSString*) name
{
    return @"CLONE-COMPLETE";
}

- (NSURL*) bundleResource
{
    return [self.attributes objectForKey:@"bundleResource"];
}

@end
