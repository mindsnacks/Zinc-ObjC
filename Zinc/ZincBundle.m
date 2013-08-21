//
//  ZCBundle.m
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincBundle+Private.h"

#import "ZincInternals.h"
#import "ZincRepoBundleManager.h"

@interface ZincBundle ()
@property (nonatomic, strong, readwrite) ZincRepoBundleManager* bundleManager;
@property (nonatomic, strong, readwrite) ZincRepo* repo;
@property (nonatomic, copy, readwrite) NSString* bundleID;
@property (nonatomic, assign, readwrite) ZincVersion version;
@property (nonatomic, strong, readwrite) NSURL* url;
@property (nonatomic, strong, readwrite) NSBundle* bundle;
@end

@implementation ZincBundle

- (id) initWithRepoBundleManager:(ZincRepoBundleManager*)bundleManager bundleID:(NSString*)bundleID version:(ZincVersion)version bundleURL:(NSURL*)bundleURL
{
    self.bundleManager = bundleManager;
    self.repo = self.bundleManager.repo; // make sure we retain the repo as well
    self.bundleID = bundleID;
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
    [self.bundleManager bundleWillDeallocate:self];
}

- (NSURL*) resource
{
    return [NSURL zincResourceForBundleWithID:self.bundleID version:self.version];
}

- (BOOL)isKindOfClass:(Class)aClass
{
    return aClass == [ZincBundle class] || aClass == [NSBundle class];
}

- (NSBundle*) NSBundle
{
    return (NSBundle*)self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature* sig = [self.bundle methodSignatureForSelector:aSelector];
    return sig;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation setTarget:self.bundle];
    [anInvocation invoke];
}

#pragma mark -

+ (NSString*) catalogIDFromBundleID:(NSString*)bundleID
{
    return ZincCatalogIDFromBundleID(bundleID);
}

+ (NSString*) bundleNameFromBundleID:(NSString*)bundleID
{
    return ZincBundleNameFromBundleID(bundleID);
}

+ (NSString*) descriptorForBundleID:(NSString*)bundleID version:(ZincVersion)version
{
    return [NSString stringWithFormat:@"%@-%d", bundleID, version];
}

- (NSURL *)URLForResource:(NSString *)name
{
    // NOTE: this is re-implemented for the NSBundle (ZincBundle) category.
    // It was the only way to avoid warnings, compile errors, and runtime errors.
    return [NSURL fileURLWithPath:
            [self pathForResource:name]];
}

- (NSString *)pathForResource:(NSString *)name
{
    // NOTE: this is re-implemented for the NSBundle (ZincBundle) category.
    // It was the only way to avoid warnings, compile errors, and runtime errors.
    NSString* base = [name stringByDeletingPathExtension];
    NSString* ext = [name pathExtension];
    return [(NSBundle *)self pathForResource:base ofType:ext];
}

@end


@implementation NSBundle (ZincBundle)

- (NSURL *)URLForResource:(NSString *)name
{
    // NOTE: this is re-implemented for the ZincBundle object.
    // It was the only way to avoid warnings, compile errors, and runtime errors.
    return [NSURL fileURLWithPath:
            [self pathForResource:name]];
}

- (NSString *)pathForResource:(NSString *)name
{
    // NOTE: this is re-implemented for the ZincBundle object.
    // It was the only way to avoid warnings, compile errors, and runtime errors.
    NSString* base = [name stringByDeletingPathExtension];
    NSString* ext = [name pathExtension];
    return [self pathForResource:base ofType:ext];
}

@end
