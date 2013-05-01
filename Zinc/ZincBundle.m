//
//  ZCBundle.m
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincBundle.h"
#import "ZincBundle+Private.h"
#import "ZincResource.h"
#import "ZincRepo+Private.h"
#import "ZincUtils.h"

@interface ZincBundle ()
@property (nonatomic, retain, readwrite) ZincRepo* repo;
@property (nonatomic, retain, readwrite) NSString* bundleId;
@property (nonatomic, assign, readwrite) ZincVersion version;
@property (nonatomic, retain, readwrite) NSURL* url;
@property (nonatomic, retain, readwrite) NSBundle* bundle;
@end

@implementation ZincBundle

@synthesize repo = _repo;
@synthesize bundleId = _bundleId;
@synthesize version = _version;
@synthesize url = _url;
@synthesize bundle = _bundle;

- (id) initWithRepo:(ZincRepo*)repo bundleId:(NSString*)bundleId version:(ZincVersion)version bundleURL:(NSURL*)bundleURL
{
    self.repo = repo;
    self.bundleId = bundleId;
    self.version = version;
    self.url = bundleURL;
    self.bundle = [NSBundle bundleWithURL:bundleURL];
    
    if (self.bundle == nil) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"bundle could not be found"];
    }

    return self;
}

- (void) dealloc 
{
    [self.repo bundleWillDeallocate:self];
    [_repo release];
    [_bundle release];
    [_bundleId release];
    [_url release];
    [super dealloc];
}

- (NSURL*) resource
{
    return [NSURL zincResourceForBundleWithId:self.bundleId version:self.version];
}
 
- (BOOL)isKindOfClass:(Class)aClass
{
    return aClass == [ZincBundle class] || aClass == [NSBundle class];
}

- (NSBundle*) NSBundle
{
//    return [NSBundle bundleWithURL:self.url];
    return (NSBundle*)self;
}

- (id)forwardingTargetForSelector:(SEL)selector
{
    return self.bundle;
}


#pragma mark -

+ (NSString*) catalogIdFromBundleId:(NSString*)bundleId
{
    return ZincCatalogIdFromBundleId(bundleId);
}

+ (NSString*) bundleNameFromBundleId:(NSString*)bundleId
{
    return ZincBundleNameFromBundleId(bundleId);
}

+ (NSString*) descriptorForBundleId:(NSString*)bundleId version:(ZincVersion)version
{
    return [NSString stringWithFormat:@"%@-%d", bundleId, version];
}

@end



@implementation NSBundle (ZincBundle)

- (NSURL *)URLForResource:(NSString *)name
{
    return [NSURL fileURLWithPath:
            [self pathForResource:name]];
}

- (NSString *)pathForResource:(NSString *)name
{
    NSString* base = [name stringByDeletingPathExtension];
    NSString* ext = [name pathExtension];
    return [self pathForResource:base ofType:ext];
}

@end
