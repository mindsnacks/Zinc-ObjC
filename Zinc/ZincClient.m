//
//  ZCBundleManager.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincClient.h"
#import "ZCBundle.h"
#import "ZCBundle+Private.h"
#import "NSFileManager+Zinc.h"
#import "ZCRemoteRepository.h"
#import "ZincIndex.h"
#import "KSJSON.h"
#import "AFNetworking.h"

static ZincClient* _defaultClient = nil;


@interface ZincClient ()
@property (nonatomic, retain) NSOperationQueue* networkOperationQueue;
@property (nonatomic, retain) NSMutableSet* repoURLs;
@property (nonatomic, retain) NSMutableSet* bundleURLs;
@property (nonatomic, retain) NSCache* bundleCache;
@end

@implementation ZincClient

@synthesize delegate = _delegate;
@synthesize networkOperationQueue = _networkOperationQueue;
@synthesize repoURLs = _repoURLs;
@synthesize bundleURLs = _bundleURLs;
@synthesize bundleCache = _bundleCache;

+ (ZincClient*) defaultClient
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultClient = [[ZincClient alloc] init];
    });
    return _defaultClient;
}

- (id) initWithNetworkOperationQueue:(NSOperationQueue*)operationQueue
{
    self = [super init];
    if (self) {
        self.networkOperationQueue = operationQueue;
        self.repoURLs = [NSMutableSet set];
        self.bundleURLs = [NSMutableSet set];
        self.bundleCache = [[[NSCache alloc] init] autorelease];
    }
    return self;
}

- (id) init
{
    NSOperationQueue* operationQueue = [[[NSOperationQueue alloc] init] autorelease];
    [operationQueue setMaxConcurrentOperationCount:kZCBundleManagerDefaultNetworkOperationCount];
    return [self initWithNetworkOperationQueue:operationQueue];
}

- (void)dealloc
{
    self.networkOperationQueue = nil;
    // TODO: stop operations?
    self.repoURLs = nil;
    self.bundleURLs = nil;
    self.bundleCache = nil;
    [super dealloc];
}

#pragma mark Repo Registration

- (void) addRepoWithURL:(NSURL*)url
{
    [self.repoURLs addObject:url];
}

- (void) refreshReposWithCompletion:(ZCBasicBlock)completion
{
    for (NSURL* repoURL in self.repoURLs) {

        ZCRemoteRepository* remote = [ZCRemoteRepository remoteRepositoryWitURL:repoURL];
        NSURLRequest* req = [remote urlRequestForIndex];
                
        AFHTTPRequestOperation* op = [[AFHTTPRequestOperation alloc] initWithRequest:req];
        op.completionBlock = ^{
            
            NSError* jsonError = nil;
            id json = [KSJSON deserializeString:op.responseString error:&jsonError];
            if (json == nil) {
                [self.delegate bundleManager:self didEncounterError:jsonError];
                completion(nil, nil, jsonError);
                return;
            }
            ZincIndex* index = [[[ZincIndex alloc] initWithDictionary:json] autorelease];
            completion(index, nil, nil);
        };
        
        [self.networkOperationQueue addOperation:op];
        [op release];
    }
}

- (void) getRepoIndexDidFinish:(NSData*)data userInfo:(id)userInfo error:(NSError*)error
{
    ZCBasicBlock completion = (ZCBasicBlock)userInfo;
    if (error != nil) {
        [self.delegate bundleManager:self didEncounterError:error];
        completion(nil, nil, error);
        return;
    }
    
    // TODO: get mime type
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError* jsonError = nil;
    id json = [KSJSON deserializeString:string error:&jsonError];
    if (json == nil) {
        [self.delegate bundleManager:self didEncounterError:jsonError];
        completion(nil, nil, error);
        return;
    }
    completion(json, nil, nil);
    
}

#pragma mark Bundle Registration

//- (BOOL) registerBundleWithURL:(NSURL*)url error:(NSError**)outError
//{
//    if ([self.bundleURLs containsObject:url]) {
//        return YES;
//    }
//    
//    if ([[NSFileManager defaultManager] zinc_directoryExistsAtURL:url]) {
//        AMErrorAssignIfNotNil(outError, ZCError(ZINC_ERR_INVALID_DIRECTORY));
//        return NO;
//    }
//    
//    // TODO: check for the info file
//    
//    [self.bundleURLs addObject:url];
//    return YES;
//}
//
//- (BOOL) registerBundleWithPath:(NSString*)path error:(NSError**)outError
//{
//    return [self registerBundleWithURL:[NSURL fileURLWithPath:path] error:outError];
//}
//
//- (void) unregisterBundleWithURL:(NSURL*)url
//{
//    @synchronized(self) {
//        [self.bundleURLs removeObject:url];
//    }
//}
//
//- (void) unregisterBundleWithPath:(NSString*)path
//{
//    [self unregisterBundleWithURL:[NSURL fileURLWithPath:path]];
//}
//
//- (ZCBundle*) bundleWithURL:(NSURL*)url error:(NSError**)outError
//{
//    @synchronized(self) {
//        ZCBundle* bundle = [self.bundleCache objectForKey:url];
//        if (bundle == nil) {
//            bundle = [ZCBundle bundleWithURL:url error:outError];
//            if (bundle == nil) {
//                return nil;
//            }
//            if ([self registerBundleWithURL:[bundle url] error:outError]) {
//                return nil;
//            }
//            [self.bundleCache setObject:bundle forKey:[bundle url]];
//        }
//        return bundle;
//    }
//}
//
//- (ZCBundle*) bundleWithURL:(NSURL*)url version:(ZincVersion)version error:(NSError**)outError
//{
//    ZCBundle* bundle = [self bundleWithURL:url error:outError];
//    if (bundle == nil) {
//        return nil;
//    }
//    bundle.version = version;
//    return bundle;
//}
//
//- (ZCBundle*) bundleWithPath:(NSString*)path error:(NSError**)outError;
//{
//    return [self bundleWithURL:[NSURL fileURLWithPath:path] error:outError];
//}
//
//- (ZCBundle*) bundleWithPath:(NSString*)path version:(ZincVersion)version error:(NSError**)outError;
//{
//    return [self bundleWithURL:[NSURL fileURLWithPath:path] version:version error:outError];
//}


@end
