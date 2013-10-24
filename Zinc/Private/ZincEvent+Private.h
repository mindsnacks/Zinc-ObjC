//
//  ZincEvent+Private.h
//  Zinc-ObjC
//
//  Created by Javier Soto on 4/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincEvent.h"

@interface ZincEvent ()

- (id) initWithType:(ZincEventType)type source:(NSDictionary*)source;
- (id) initWithType:(ZincEventType)type source:(NSDictionary*)source attributes:(NSDictionary*)attributes;;

+ (NSString *)notificationName;

@end


@interface ZincErrorEvent ()

- (id) initWithError:(NSError*)error source:(NSDictionary*)source attributes:(NSDictionary*)attributes;
@property (strong, readwrite) NSError* error;

+ (id) eventWithError:(NSError*)error source:(NSDictionary*)source;
+ (id) eventWithError:(NSError*)error source:(NSDictionary*)source attributes:(NSDictionary*)attributes;

@end


@interface ZincDeleteEvent ()

+ (id) deleteEventForPath:(NSString*)path source:(NSDictionary*)source;

@end


@interface ZincDownloadBeginEvent ()

+ (id) downloadBeginEventForURL:(NSURL*)url;

@end


@interface ZincDownloadCompleteEvent ()

+ (id) downloadCompleteEventForURL:(NSURL*)url size:(long long)size;

@end


@interface ZincBundleCloneBeginEvent ()

+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource context:(id)context;
+ (id) bundleCloneBeginEventForBundleResource:(NSURL*)bundleResource source:(NSDictionary*)source context:(id)context;

@end


@interface ZincBundleCloneCompleteEvent ()

+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource source:(NSDictionary*)source context:(id)context success:(BOOL)success;
+ (id) bundleCloneCompleteEventForBundleResource:(NSURL*)bundleResource context:(id)context success:(BOOL)success;

@end


@interface ZincArchiveExtractBeginEvent ()

+ (id) archiveExtractBeginEventForResource:(NSURL*)archiveResource;

@end


@interface ZincArchiveExtractCompleteEvent ()

+ (id) archiveExtractCompleteEventForResource:(NSURL*)archiveResource context:(id)context;

@end


@interface ZincMaintenanceBeginEvent ()

+ (id) maintenanceEventWithAction:(NSString*)category;

@end


@interface ZincMaintenanceCompleteEvent ()

+ (id) maintenanceEventWithAction:(NSString*)action;

@end


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

