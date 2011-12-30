//
//  ZCBundleManager.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincClient.h"
#import "ZincBundle.h"
#import "ZincManifest.h"
#import "ZincBundle+Private.h"
#import "NSFileManager+Zinc.h"
#import "ZincSource.h"
#import "ZincCatalog.h"
#import "KSJSON.h"
#import "AFNetworking.h"

#define CATALOGS_DIR_NAME @"catalogs"
#define MANIFESTS_DIR_NAME @"manifests"

static ZincClient* _defaultClient = nil;

@interface ZincClient ()
@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSOperationQueue* networkOperationQueue;
@property (nonatomic, retain) NSOperationQueue* controlOperationQueue;
@property (nonatomic, retain) NSOperationQueue* fileOperationQueue;
@property (nonatomic, retain) NSMutableSet* sourceURLs;
@property (nonatomic, retain) NSMutableDictionary* sourcesByCatalog;
@property (nonatomic, retain) NSMutableDictionary* trackedBundles;
@property (nonatomic, retain) NSCache* cache;
@property (nonatomic, retain) NSFileManager* fileManager;
@property (nonatomic, retain) NSTimer* refreshTimer;

- (BOOL) createDirectoriesIfNeeded:(NSError**)outError;
- (NSString*) catalogsPath;
- (NSString*) manifestsPath;
- (ZincCatalog*) catalogWithIdentifier:(NSString*)source error:(NSError**)outError;
- (void) addSource:(ZincSource*)source forCatalog:(ZincCatalog*)catalog;
- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
@end

@interface ZincBundleUpdateOperation : NSOperation
@property (nonatomic, assign) ZincClient* client;
@property (nonatomic, retain) ZincManifest* manifest;
@end

@interface ZincRepoAtomicFileWriteOperation : NSOperation
- (id)initWithClient:(ZincClient*)client data:(NSData*)data path:(NSString*)path;
@property (nonatomic, assign) ZincClient* client;
@property (nonatomic, retain) NSData* data;
@property (nonatomic, retain) NSString* path;
@property (nonatomic, retain) NSError* error;
@end

@implementation ZincClient

@synthesize delegate = _delegate;
@synthesize url = _url;
@synthesize networkOperationQueue = _networkOperationQueue;
@synthesize controlOperationQueue = _controlOperationQueue;
@synthesize fileOperationQueue = _fileOperationQueue;
@synthesize sourceURLs = _sourceURLs;
@synthesize sourcesByCatalog = _sourcesByCatalog;
@synthesize trackedBundles = _trackedBundles;
@synthesize fileManager = _fileManager;
@synthesize cache = _cache;
@synthesize refreshInterval = _refreshInterval;
@synthesize refreshTimer = _refreshTimer;

+ (ZincClient*) defaultClient
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* defaultPath = [ZincGetApplicationDocumentsDirectory() stringByAppendingPathComponent:@"zinc"];
        _defaultClient = [[ZincClient alloc] initWithURL:[NSURL fileURLWithPath:defaultPath]];
    });
    return _defaultClient;
}

+ (ZincClient*) clientWithURL:(NSURL*)fileURL error:(NSError**)outError
{
    ZincClient* client = [[[ZincClient alloc] initWithURL:fileURL] autorelease];
    if (![client createDirectoriesIfNeeded:outError]) {
        return nil;
    }
    return client;
}

- (id) initWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)operationQueue
{
    self = [super init];
    if (self) {
        self.url = fileURL;
        self.controlOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
        self.controlOperationQueue.maxConcurrentOperationCount = 1;
        self.fileOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
        self.fileOperationQueue.maxConcurrentOperationCount = 1;
        self.networkOperationQueue = operationQueue;
        self.sourceURLs = [NSMutableSet set];
        self.sourcesByCatalog = [NSMutableDictionary dictionary];
        self.trackedBundles = [NSMutableDictionary dictionary];
        self.fileManager = [[[NSFileManager alloc] init] autorelease];
        self.cache = [[[NSCache alloc] init] autorelease];
        self.refreshInterval = 5.0;
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval
                                                             target:self
                                                           selector:@selector(refreshTimerFired:)
                                                           userInfo:nil
                                                            repeats:YES];
    }
    return self;
}

- (void) refreshTimerFired:(NSTimer*)timer
{
    __block typeof(self) blockself = self;
    
    [blockself refreshSourcesWithCompletion:^{
        
        ZINC_DEBUG_LOG(@"beep");
        
        [blockself refreshBundlesWithCompletion:^{
            
            ZINC_DEBUG_LOG(@"honk");

        }];

    }];
}

- (id) initWithURL:(NSURL*)fileURL
{
//    NSString* defaultPath = [GetApplicationDocumentsDirectory() stringByAppendingPathComponent:@"zinc"];
    NSOperationQueue* operationQueue = [[[NSOperationQueue alloc] init] autorelease];
    [operationQueue setMaxConcurrentOperationCount:kZCBundleManagerDefaultNetworkOperationCount];
    return [self initWithURL:fileURL networkOperationQueue:operationQueue];
}

- (void)dealloc
{
    self.url = nil;
    // TODO: stop operations?
    self.controlOperationQueue = nil;
    self.fileOperationQueue = nil;
    self.networkOperationQueue = nil;
    self.sourceURLs = nil;
    self.sourcesByCatalog = nil;
    self.trackedBundles = nil;
    self.cache = nil;
    [super dealloc];
}

#pragma mark Filesystem Utilities

- (BOOL) createDirectoriesIfNeeded:(NSError**)outError
{
    if (![self.fileManager zinc_createDirectoryIfNeededAtPath:[self catalogsPath] error:outError]) {
        return NO;
    }
    if (![self.fileManager zinc_createDirectoryIfNeededAtPath:[self manifestsPath] error:outError]) {
        return NO;
    }
    return YES;
}

- (BOOL) writeDataAtomically:(NSData*)data toPath:(NSString*)path error:(NSError**)outError
{
    if (![data writeToFile:path options:NSDataWritingAtomic error:outError]) {
        return NO;
    }
    ZINC_DEBUG_LOG(@"[ZincClient 0x%x] Wrote %@", (int)self, path);
    ZincAddSkipBackupAttributeToFile([NSURL fileURLWithPath:path]);
    return YES;
}

#pragma mark Path Helpers

- (NSString*) catalogsPath
{
    return [[self.url path] stringByAppendingPathComponent:CATALOGS_DIR_NAME];
}

- (NSString*) manifestsPath
{
    return [[self.url path] stringByAppendingPathComponent:MANIFESTS_DIR_NAME];
}

- (NSString*) pathForCatalogIndexWithIdentifier:(NSString*)identifier
{
    NSString* catalogFilename =  [identifier stringByAppendingPathExtension:@"json"];
    NSString* catalogPath = [[self catalogsPath] stringByAppendingPathComponent:catalogFilename];
    return catalogPath;
}

- (NSString*) pathForCatalogIndex:(ZincCatalog*)catalog
{
    return [self pathForCatalogIndexWithIdentifier:catalog.identifier];
}

- (NSString*) pathForManifestWithBundleIdentifier:(NSString*)identifier version:(ZincVersion)version
{
    NSString* manifestFilename = [NSString stringWithFormat:@"%@-%d.json", identifier, version];
    NSString* manifestPath = [[self manifestsPath] stringByAppendingPathComponent:manifestFilename];
    return manifestPath;
}

#pragma mark Internal Operations

- (void) handleError:(NSError*)error
{
    if (self.delegate == nil) return;
    
    __block typeof(self) blockself = self;
    NSOperation* op = [NSBlockOperation blockOperationWithBlock:^{
        ZINC_DEBUG_LOG(@"[ZincClient 0x%x] %@", (int)blockself, error);
        [blockself.delegate zincClient:blockself didEncounterError:error];
    }];
    
    [[NSOperationQueue mainQueue] addOperation:op];
}

- (ZincRepoAtomicFileWriteOperation*) queuedFileWriteOperationForData:(NSData*)data path:(NSString*)path
{
    ZincRepoAtomicFileWriteOperation* op = [[[ZincRepoAtomicFileWriteOperation alloc] initWithClient:self data:data path:path] autorelease];
    [self.fileOperationQueue addOperation:op];
    return op;
}

- (AFHTTPRequestOperation*) queuedHTTPRequestOperationForRequest:(NSURLRequest*)request
{
    AFHTTPRequestOperation* op = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    [self.networkOperationQueue addOperation:op];
    ZINC_DEBUG_LOG(@"[ZincClient 0x%x] Downloading %@", (int)self, [request URL]);
    return op;
}

- (NSOperation*) downloadOperationForCatalogIndex:(ZincSource*)source
{
    __block typeof(self) blockself = self;
    NSBlockOperation* op = [NSBlockOperation blockOperationWithBlock:^{
        
        NSError* error = nil;
        
        NSURLRequest* request = [source urlRequestForCatalogIndex];
        AFHTTPRequestOperation* requestOp = [self queuedHTTPRequestOperationForRequest:request];
        [requestOp waitUntilFinished];
        if ([requestOp.response statusCode] != 200) {
            // TODO: better status code checking
            return;
        }
        
        ZincCatalog* catalog = [ZincCatalog catalogFromJSONString:requestOp.responseString error:&error];
        if (catalog == nil) {
            [blockself handleError:error];
            return;
        }
        
        NSData* data = [[catalog jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
        if (data == nil) {
            [blockself handleError:error];
            return;
        }
        
        NSString* path = [blockself pathForCatalogIndex:catalog];
        ZincRepoAtomicFileWriteOperation* writeOp = [blockself queuedFileWriteOperationForData:data path:path];
        [writeOp waitUntilFinished];
        if (writeOp.error != nil) {
            [blockself handleError:writeOp.error];
            return;
        }
        
        [blockself addSource:source forCatalog:catalog];
    }];
    return op;
}

- (NSOperation*) downloadOperationForManifestWithBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version
{
    __block typeof(self) blockself = self;
    NSBlockOperation* op = [NSBlockOperation blockOperationWithBlock:^{

        NSError* error = nil;
        
        NSString* catalogId = [ZincBundle sourceFromBundleIdentifier:bundleId];
        NSString* bundleName = [ZincBundle nameFromBundleIdentifier:bundleId];
        ZincSource* source = [[blockself.sourcesByCatalog objectForKey:catalogId] lastObject]; // TODO: fix lastObject
        if (source == nil) {
            ZINC_DEBUG_LOG(@"source is nil");
            return;
        }

        NSURLRequest* request = [source urlRequestForBundleName:bundleName version:version];
        if (request == nil) {
            // TODO: better error
            NSAssert(0, @"request is nil");
            return;
        }
        
        AFHTTPRequestOperation* requestOp = [blockself queuedHTTPRequestOperationForRequest:request];
        [requestOp waitUntilFinished];
        if (requestOp.response.statusCode != 200) { // TODO: fix status check
            return;
        }
        
        id json = [KSJSON deserializeString:requestOp.responseString error:&error];
        if (json == nil) {
            [self handleError:error];
            return;
        }
        
        ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:json] autorelease];
        NSData* data = [[manifest jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
        if (data == nil) {
            [blockself handleError:error];
            return;
        }
        
        NSString* path = [blockself pathForManifestWithBundleIdentifier:bundleId version:manifest.version];
        ZincRepoAtomicFileWriteOperation* writeOp = [blockself queuedFileWriteOperationForData:data path:path];
        [writeOp waitUntilFinished];
        if (writeOp.error != nil) {
            [blockself handleError:writeOp.error];
            return;
        }
    }];
    return op;
}

#pragma mark Sources

- (void) addSourceURL:(NSURL*)url
{
    [self.sourceURLs addObject:url];
}

- (void) addSource:(ZincSource*)source forCatalog:(ZincCatalog*)catalog
{
    NSMutableArray* sources = [self.sourcesByCatalog objectForKey:catalog.identifier];
    if (sources == nil) {
        sources = [NSMutableArray array];
        [self.sourcesByCatalog setObject:sources forKey:catalog.identifier];
    }
    // TODO: cleaner duplicate check
    for (ZincSource* existingSource in sources) {
        if ([existingSource.url isEqual:source.url]) {
            return;
        }
    }
    [sources addObject:source];
}

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion
{
    NSOperation* parentOp = [[[NSOperation alloc] init] autorelease];
    parentOp.completionBlock = completion;
    
    for (NSURL* sourceURL in self.sourceURLs) {
        ZincSource* source = [ZincSource sourceWithURL:sourceURL];
        NSOperation* downloadOp = [self downloadOperationForCatalogIndex:source];
        [self.controlOperationQueue addOperation:downloadOp];        
        [parentOp addDependency:downloadOp];
    }
    [self.controlOperationQueue addOperation:parentOp];
}

#pragma mark Catalogs

- (NSString*) cacheKeyForCatalogIdentifier:(NSString*)identifier
{
    return [@"ZincCatalog:" stringByAppendingString:identifier];
}

- (ZincCatalog*) loadCatalogWithIdentifier:(NSString*)identifier error:(NSError**)outError
{
    NSString* catalogPath = [[[self catalogsPath] stringByAppendingPathComponent:identifier] stringByAppendingPathExtension:@"json"];
    NSString* jsonString = [NSString stringWithContentsOfFile:catalogPath encoding:NSUTF8StringEncoding error:outError];
    if (jsonString == nil) {
        return nil;
    }
    NSDictionary* jsonDict = [KSJSON deserializeString:jsonString error:outError];
    if (jsonDict == nil) {
        return nil;
    }
    ZincCatalog* catalog = [[[ZincCatalog alloc] initWithDictionary:jsonDict] autorelease];
    return catalog;
}

- (ZincCatalog*) catalogWithIdentifier:(NSString*)identifier error:(NSError**)outError
{
    @synchronized(self) {
        ZincCatalog* catalog = [self.cache objectForKey:[self cacheKeyForCatalogIdentifier:identifier]];
        if (catalog == nil) {
            catalog = [self loadCatalogWithIdentifier:identifier error:outError];
            if (catalog != nil) {
                [self.cache setObject:catalog forKey:[self cacheKeyForCatalogIdentifier:identifier]];
            }
        }
        return catalog;
    }
}

#pragma mark Bundles

- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version
{
    NSString* path = [self pathForManifestWithBundleIdentifier:bundleId version:version];
    return [self.fileManager fileExistsAtPath:path];
}

- (ZincVersion) versionForBundleIdentifier:(NSString*)bundleId label:(NSString*)label
{
    NSString* catalogId = [ZincBundle sourceFromBundleIdentifier:bundleId];
    NSString* bundleName = [ZincBundle nameFromBundleIdentifier:bundleId];
    ZincCatalog* catalog = [self catalogWithIdentifier:catalogId error:NULL];
    if (catalog == nil) {
        return ZincVersionInvalid;
    }
    return [catalog versionForBundleName:bundleName label:label];
}

- (BOOL) hasManifestForBundleIdentifier:(NSString *)bundleId label:(NSString*)label
{
    NSString* catalogId = [ZincBundle sourceFromBundleIdentifier:bundleId];
    NSString* bundleName = [ZincBundle nameFromBundleIdentifier:bundleId];
    ZincCatalog* catalog = [self catalogWithIdentifier:catalogId error:NULL];
    if (catalog == nil) {
        return NO;
    }
    ZincVersion version = [catalog versionForBundleName:bundleName label:label];
    return [self hasManifestForBundleIdentifier:bundleId version:version];
}

- (void) beginTrackingBundleWithIdentifier:(NSString*)bundleId label:(NSString*)label
{
    [self.trackedBundles setObject:label forKey:bundleId];
}

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion
{
    NSOperation* parentOp = [[[NSOperation alloc] init] autorelease];
    parentOp.completionBlock = completion;

    for (NSString* bundleId in [self.trackedBundles allKeys]) {
        NSString* label = [self.trackedBundles objectForKey:bundleId];
        ZincVersion version = [self versionForBundleIdentifier:bundleId label:label];
        if (version != ZincVersionInvalid) {
            if (![self hasManifestForBundleIdentifier:bundleId version:version]) {
                NSOperation* downloadOp = [self downloadOperationForManifestWithBundleIdentifier:bundleId version:version];
                [self.controlOperationQueue addOperation:downloadOp];        
                [parentOp addDependency:downloadOp];
            }
        }
    }
    [self.controlOperationQueue addOperation:parentOp];
}

#pragma mark Bundle Registration

//- (BOOL) registerBundleWithURL:(NSURL*)url error:(NSError**)outError
//{
//    if ([self.trackedBundles containsObject:url]) {
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
//    [self.trackedBundles addObject:url];
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
//        [self.trackedBundles removeObject:url];
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

// -----------------------------------------------------------------------------
#pragma mark -

@implementation ZincBundleUpdateOperation

@synthesize client = _client;
@synthesize manifest = _manifest;

- (void)dealloc
{
    self.client = nil;
    self.manifest = nil;
    [super dealloc];
}

- (void) main
{
    
}

@end


// -----------------------------------------------------------------------------
#pragma mark - 

@implementation ZincRepoAtomicFileWriteOperation

@synthesize client = _client;
@synthesize data = _data;
@synthesize path = _path;
@synthesize error = _error;

- (id)initWithClient:(ZincClient*)client data:(NSData*)data path:(NSString*)path
{
    self = [super init];
    if (self) {
        self.client = client;
        self.data = data;
        self.path = path;
    }
    return self;
}

- (void)dealloc
{
    self.client = nil;
    self.path = nil;
    self.data = nil;
    self.error = nil;
    [super dealloc];
}

- (void) main
{
    NSError* error = nil;
    if (![self.client writeDataAtomically:self.data toPath:self.path error:&error]) {
        self.error = error;
    }
}

@end