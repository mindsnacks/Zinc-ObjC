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
#import "ZincRepo.h"

static const char* queue_name_for_url(NSURL* url) {
    return [[kZincPackageName stringByAppendingFormat:@".bundle#%@",
             [url absoluteString]] cStringUsingEncoding:NSUTF8StringEncoding];
}

static NSMutableDictionary * _ZCBundle_sharedURLMap;


@interface ZincBundle ()
@property (nonatomic, assign) dispatch_queue_t queue;
@end


@implementation ZincBundle

//@synthesize version = _version;
@synthesize manifest = _manifest;
@synthesize repo = _repo;
@synthesize queue = _queue;
@synthesize manager = _manager;

+ (void) initialize
{
	if ( self == [ZincBundle class] ) {
		_ZCBundle_sharedURLMap = [[NSMutableDictionary alloc] init];
	}
}

- (id) initWithRepo:(ZincRepo*)repo
{
    self = [super init];
    if (self) {
        //self.queue = dispatch_queue_create(queue_name_for_url(self.url), NULL);
        self.repo = repo;
    }
    return self;
}

- (void) dealloc 
{
    // TODO: !!!: restore mapping
    
//    // -- remove from sharedMap
//	@synchronized(_ZCBundle_sharedURLMap) {
//		[_ZCBundle_sharedURLMap removeObjectForKey:[[self url] absoluteString]];
//	}
    
    self.manifest = nil;
    self.repo = nil;
    [super dealloc];
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

- (NSArray*) availableVersions;
{
    return nil;
}

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


@end
