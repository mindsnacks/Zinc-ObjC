//
//  ZCBundle.m
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincBundle.h"
#import "ZincBundle+Private.h"
#import "NSFileManager+Zinc.h"
#import "ZincClient.h"

@interface ZincBundle ()
@property (nonatomic, retain, readwrite) ZincClient* repo;
@property (nonatomic, retain, readwrite) NSString* bundleId;
@property (nonatomic, assign, readwrite) ZincVersion version;
@end

@implementation ZincBundle

@synthesize bundleId = _bundleId;
@synthesize version = _version;
@synthesize repo = _repo;
@synthesize manifest = _manifest;

- (id) initWithBundleId:(NSString*)bundleId version:(ZincVersion)version repo:(ZincClient*)repo
{
    self = [super init];
    if (self) {
        self.repo = repo;
        self.bundleId = bundleId;
        self.version = version;
    }
    return self;
}

- (void) dealloc 
{
    self.manifest = nil;
    self.repo = nil;
    [super dealloc];
}

- (NSURL*) urlForResource:(NSString*)resource
{
    NSString* path = [self pathForResource:resource];
    if (path != nil) {
        return [NSURL fileURLWithPath:path];
    }
    return nil;
}

- (NSString*) pathForResource:(NSString*)path
{
//    if (self.manifest == nil) return nil;
//    
    NSString* sha = [self.manifest shaForFile:path];
//    if (sha == nil) return nil;
    
    return [self.repo pathForFileWithSHA:sha];
}


//+ (ZCBundle*) bundleWithURL:(NSURL*)url error:(NSError**)outError
//{
//    ZincRepo* zcfs = [ZincRepo zincRepoWithURL:url error:outError];
//    if (zcfs == nil) {
//        return nil;
//    }
//    
//    ZCBundle* bundle = [[[ZCBundle alloc] initWithRepo:zcfs] autorelease];
//    return bundle;
//}

//+ (ZCBundle*) bundleWithURL:(NSURL*)url version:(ZincVersion)version error:(NSError**)outError
//{
//    ZCBundle* bundle = [self bundleWithURL:url error:outError];
//    if (bundle == nil) {
//        return nil;
//    }
//
//    return bundle;
//}

//+ (ZCBundle*) bundleWithPath:(NSString*)path error:(NSError**)outError
//{
//    return [self bundleWithURL:[NSURL fileURLWithPath:path] error:outError];
//}

//+ (ZCBundle*) bundleWithPath:(NSString*)path version:(ZincVersion)version error:(NSError**)outError
//{
//    return [self bundleWithURL:[NSURL fileURLWithPath:path] version:version error:outError];
//}


#pragma mark Accessors

//- (NSArray*) availableVersions;
//{
//    return nil;
//}
//
//- (NSURL*) url
//{
//    return self.fileSystem.url;
//}

#pragma mark -

//- (NSURL*) urlForResource:(NSURL*)url
//{
//    return [self.fileSystem urlForResource:url version:self.version];
//}
//
//- (NSString*) pathForResource:(NSString*)path
//{
//    return [self.fileSystem pathForResource:path version:self.version];
//}


+ (NSString*) sourceFromBundleIdentifier:(NSString*)bundleId
{
    NSArray* comps = [bundleId componentsSeparatedByString:@"."];
    NSString* sourceId = [[comps subarrayWithRange:NSMakeRange(0, [comps count]-1)] componentsJoinedByString:@"."];
    return sourceId;
}

+ (NSString*) nameFromBundleIdentifier:(NSString*)bundleId
{
    return [[bundleId componentsSeparatedByString:@"."] lastObject];
}

+ (NSString*) descriptorForBundleId:(NSString*)bundleId version:(ZincVersion)version
{
    return [NSString stringWithFormat:@"%@-%d", bundleId, version];
}

- (NSString*) descriptor
{
    return [[self class] descriptorForBundleId:self.bundleId version:self.version];
}


@end
