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
    return self;
}

- (void) dealloc 
{
    // TODO: notify dealloc
    self.repo = nil;
    self.bundle = nil;
    self.bundleId = nil;
    self.url = nil;
    [super dealloc];
}

//- (NSURL *)URLForResource:(NSString *)name withExtension:(NSString *)ext
//{
//    NSString* p = [name stringByAppendingPathExtension:ext];
//    return [self URLForResource:p];
//}

- (NSURL *)URLForResource:(NSString *)name
{
    return [self.url URLByAppendingPathComponent:name];
}

//- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext
//{
//    NSString* p = [name stringByAppendingPathExtension:ext];
//    return [self pathForResource:p];
//}

- (NSString *)pathForResource:(NSString *)name
{
    return [[self.url path] stringByAppendingPathComponent:name];
}

- (NSBundle*) NSBundle
{
//    return [NSBundle bundleWithURL:self.url];
    return (NSBundle*)self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    id target = self;
    if (![self respondsToSelector:@selector(aSelector)]) {
        target = self.bundle;
    }
    return [target methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation setTarget:self.bundle];
    [anInvocation invoke];
}


#pragma mark -

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



@implementation NSBundle (ZincBundle)

- (NSURL *)URLForResource:(NSString *)name
{
    return [[self bundleURL] URLByAppendingPathComponent:name];
}

- (NSString *)pathForResource:(NSString *)name
{
    return [[[self bundleURL] path] stringByAppendingPathComponent:name];
}

@end
