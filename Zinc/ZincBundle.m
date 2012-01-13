//
//  ZCBundle.m
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincBundle.h"
#import "ZincBundle+Private.h"

@interface ZincBundle ()
@property (nonatomic, retain, readwrite) NSString* bundleId;
@property (nonatomic, assign, readwrite) ZincVersion version;
@property (nonatomic, retain, readwrite) NSURL* url;
@end

@implementation ZincBundle

@synthesize bundleId = _bundleId;
@synthesize version = _version;
@synthesize url = _url;

- (id) initWithBundleId:(NSString*)bundleId version:(ZincVersion)version bundleURL:(NSURL*)bundleURL
{
    self.bundleId = bundleId;
    self.version = version;
    self.url = bundleURL;
    return self;
}

- (void) dealloc 
{
    self.bundleId = nil;
    self.url = nil;
    [super dealloc];
}

//- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
//{
//    return [(id)self.nsbundle methodSignatureForSelector:aSelector];
//}
//
//- (void)forwardInvocation:(NSInvocation *)anInvocation
//{
//    [anInvocation setTarget:self.nsbundle];
//    [anInvocation invoke];
//}

- (NSURL *)URLForResource:(NSString *)name withExtension:(NSString *)ext
{
    NSString* p = [name stringByAppendingPathExtension:ext];
    return [self URLForResource:p];
}

- (NSURL *)URLForResource:(NSString *)name
{
    return [self.url URLByAppendingPathComponent:name];
}

- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext
{
    NSString* p = [name stringByAppendingPathExtension:ext];
    return [self pathForResource:p];
}

- (NSString *)pathForResource:(NSString *)name
{
    return [[self.url path] stringByAppendingPathComponent:name];
}

- (NSBundle*) nsbundle
{
    return [NSBundle bundleWithURL:self.url];
}

+ (NSString*) catalogIdFromBundleId:(NSString*)bundleId
{
    NSArray* comps = [bundleId componentsSeparatedByString:@"."];
    NSString* sourceId = [[comps subarrayWithRange:NSMakeRange(0, [comps count]-1)] componentsJoinedByString:@"."];
    return sourceId;
}

+ (NSString*) bundleNameFromBundleId:(NSString*)bundleId
{
    return [[bundleId componentsSeparatedByString:@"."] lastObject];
}

+ (NSString*) descriptorForBundleId:(NSString*)bundleId version:(ZincVersion)version
{
    return [NSString stringWithFormat:@"%@-%d", bundleId, version];
}

@end
