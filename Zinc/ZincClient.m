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
#import "ZincOperation+Private.h"
#import "KSJSON.h"
#import "AFNetworking.h"
#import "sha1.h"
#import "MAWeakDictionary.h"

#define CATALOGS_DIR_NAME @"catalogs"
#define MANIFESTS_DIR_NAME @"manifests"
#define FILES_DIR_NAME @"files"

static ZincClient* _defaultClient = nil;

@interface ZincClient ()
@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSOperationQueue* networkOperationQueue;
@property (nonatomic, retain) NSOperationQueue* primaryOperationQueue;
@property (nonatomic, retain) NSOperationQueue* fileOperationQueue;
@property (nonatomic, retain) NSMutableDictionary* operationsByName;
@property (nonatomic, retain) NSMutableSet* sourceURLs;
@property (nonatomic, retain) NSMutableDictionary* sourcesByCatalog;
@property (nonatomic, retain) NSMutableDictionary* trackedBundles;
@property (nonatomic, retain) NSCache* cache;
@property (nonatomic, retain) NSFileManager* fileManager;
@property (nonatomic, retain) NSTimer* refreshTimer;
@property (nonatomic, retain) MAWeakDictionary* loadedBundles;

- (BOOL) createDirectoriesIfNeeded:(NSError**)outError;
- (NSString*) catalogsPath;
- (NSString*) manifestsPath;
- (NSString*) filesPath;

- (NSString*) cacheKeyForCatalogIdentifier:(NSString*)identifier;
- (NSString*) cacheKeyManifestWithBundleIdentifier:(NSString*)identifier version:(ZincVersion)version;
- (NSString*) cacheKeyForBundleIdentifier:(NSString*)identifier version:(ZincVersion)version;

- (void) registerSource:(ZincSource*)source forCatalog:(ZincCatalog*)catalog;
- (NSArray*) sourcesForCatalogIdentifier:(NSString*)catalogId;

- (ZincCatalog*) catalogWithIdentifier:(NSString*)source error:(NSError**)outError;
- (ZincVersion) versionForBundleIdentifier:(NSString*)bundleId label:(NSString*)label;

- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
- (ZincManifest*) manifestWithBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError;

// - (void) ensureFilesForBundleIdentifier:(NSString*)bundleIdentifier version:(ZincVersion)version;

@end

@interface ZincRepoAtomicFileWriteOperation : ZincOperation
- (id)initWithClient:(ZincClient*)client data:(NSData*)data path:(NSString*)path;
@property (nonatomic, retain) NSData* data;
@property (nonatomic, retain) NSString* path;
@end

@interface ZincRepoCatalogIndexUpdateOperation : ZincOperation
- (id)initWithClient:(ZincClient *)client source:(ZincSource*)source;
@property (nonatomic, retain) ZincSource* source;
@end

@interface ZincRepoFileUpdateOperation : ZincOperation
- (id)initWithClient:(ZincClient*)client source:(ZincSource*)souce sha:(NSString*)sha;
@property (nonatomic, retain) ZincSource* source;
@property (nonatomic, retain) NSString* sha;
@end

@interface ZincRepoManifestUpdateOperation : ZincOperation
- (id)initWithClient:(ZincClient *)client bundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
+ (NSString*) nameForBundleId:(NSString*)bundleId version:(ZincVersion)version;
@property (nonatomic, retain) NSString* bundleId;
@property (nonatomic, assign) ZincVersion version;
@end

@interface ZincRepoEnsureBundleOperation : ZincOperation
- (id)initWithClient:(ZincClient *)client bundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
@property (nonatomic, retain) NSString* bundleId;
@property (nonatomic, assign) ZincVersion version;
@end

@implementation ZincClient

@synthesize delegate = _delegate;
@synthesize url = _url;
@synthesize networkOperationQueue = _networkOperationQueue;
@synthesize primaryOperationQueue = _primaryOperationQueue;
@synthesize fileOperationQueue = _fileOperationQueue;
@synthesize operationsByName = _operationsByName;
@synthesize sourceURLs = _sourceURLs;
@synthesize sourcesByCatalog = _sourcesByCatalog;
@synthesize trackedBundles = _trackedBundles;
@synthesize fileManager = _fileManager;
@synthesize cache = _cache;
@synthesize refreshInterval = _refreshInterval;
@synthesize refreshTimer = _refreshTimer;
@synthesize loadedBundles = _loadedBundles;

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
        self.primaryOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
        //self.primaryOperationQueue.maxConcurrentOperationCount = 1;
        self.fileOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
        self.fileOperationQueue.maxConcurrentOperationCount = 1;
        self.networkOperationQueue = operationQueue;
        self.operationsByName = [NSMutableDictionary dictionary];
        self.sourceURLs = [NSMutableSet set];
        self.sourcesByCatalog = [NSMutableDictionary dictionary];
        self.trackedBundles = [NSMutableDictionary dictionary];
        self.fileManager = [[[NSFileManager alloc] init] autorelease];
        self.cache = [[[NSCache alloc] init] autorelease];
        self.refreshInterval = 5.0;
        self.loadedBundles = [NSMutableDictionary dictionary];
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
        
        [blockself refreshBundlesWithCompletion:^{
            
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
    self.primaryOperationQueue = nil;
    self.fileOperationQueue = nil;
    self.networkOperationQueue = nil;
    self.sourceURLs = nil;
    self.sourcesByCatalog = nil;
    self.trackedBundles = nil;
    self.cache = nil;
    self.loadedBundles = nil;
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
    if (![self.fileManager zinc_createDirectoryIfNeededAtPath:[self filesPath] error:outError]) {
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

- (NSString*) filesPath
{
    return [[self.url path] stringByAppendingPathComponent:FILES_DIR_NAME];
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

- (NSString*) pathForFileWithSHA:(NSString*)sha
{
    NSString* relativePath = [NSString stringWithFormat:@"%@/%@/%@",
                              [sha substringWithRange:NSMakeRange(0, 2)],
                              [sha substringWithRange:NSMakeRange(2, 2)],
                              sha];
    return [[self filesPath] stringByAppendingPathComponent:relativePath];
}

#pragma mark Internal Operations

- (ZincOperation*) getOperationWithName:(NSString*)name
{
    @synchronized(self) {

        //        NSArray* matching = [[self.primaryOperationQueue operations]
//                             filteredArrayUsingPredicate:
//                             [NSPredicate predicateWithFormat:@"name == %@", name]];
//        if (matching != nil && [matching count] > 0) {
//            return [matching objectAtIndex:0];
//        }
//        return nil;
        
        for (NSOperation* op in [self.primaryOperationQueue operations]) {
            if ([op isKindOfClass:[ZincOperation class]]) {
                ZincOperation* zop = (ZincOperation*)op;
                if ([name isEqualToString:zop.name]) {
                    return zop;
                }
            }
        }
        return nil;
    }
}

- (NSOperation*) addOperationToPrimaryQueue:(NSOperation*)operation
{
    @synchronized(self) {
        if ([operation isKindOfClass:[ZincOperation class]]) {
            NSString* name = [operation valueForKey:@"name"];
            if (name != nil) {
                NSOperation* existing = [self getOperationWithName:name];
                if (existing != nil) {
                    return existing;
                }
            }
        }
        
        [self.primaryOperationQueue addOperation:operation];
        return operation;
    }
}

- (void) handleError:(NSError*)error
{
    if (self.delegate == nil) return;
    
    __block typeof(self) blockself = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        ZINC_DEBUG_LOG(@"[ZincClient 0x%x] %@", (int)blockself, error);
        [blockself.delegate zincClient:blockself didEncounterError:error];
    }];
}

- (ZincRepoAtomicFileWriteOperation*) queuedAtomicFileWriteOperationForData:(NSData*)data path:(NSString*)path
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

//- (NSOperation*) downloadOperationForCatalogIndex:(ZincSource*)source
//{
//    __block typeof(self) blockself = self;
//    NSBlockOperation* op = [NSBlockOperation blockOperationWithBlock:^{
//        
//        NSError* error = nil;
//        
//        NSURLRequest* request = [source urlRequestForCatalogIndex];
//        AFHTTPRequestOperation* requestOp = [self queuedHTTPRequestOperationForRequest:request];
//        [requestOp waitUntilFinished];
//        if ([requestOp.response statusCode] != 200) {
//            // TODO: better status code checking
//            return;
//        }
//        
//        ZincCatalog* catalog = [ZincCatalog catalogFromJSONString:requestOp.responseString error:&error];
//        if (catalog == nil) {
//            [blockself handleError:error];
//            return;

//        }
//        
//        NSData* data = [[catalog jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
//        if (data == nil) {
//            [blockself handleError:error];
//            return;
//        }
//        
//        NSString* path = [blockself pathForCatalogIndex:catalog];
//        ZincRepoAtomicFileWriteOperation* writeOp = [blockself queuedFileWriteOperationForData:data path:path];
//        [writeOp waitUntilFinished];
//        if (writeOp.error != nil) {
//            [blockself handleError:writeOp.error];
//            return;
//        } 
//        
//        [blockself.cache setObject:catalog forKey:[self cacheKeyForCatalogIdentifier:catalog.identifier]];
//        [blockself addSource:source forCatalog:catalog];
//    }];
//    return op;
//}

#pragma mark Sources

- (void) addSourceURL:(NSURL*)url
{
    [self.sourceURLs addObject:url];
}

- (void) registerSource:(ZincSource*)source forCatalog:(ZincCatalog*)catalog
{
    @synchronized(self) {
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
}

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion
{
    NSOperation* parentOp = [[[NSOperation alloc] init] autorelease];
    parentOp.completionBlock = completion;
    
    for (NSURL* sourceURL in self.sourceURLs) {
        ZincSource* source = [ZincSource sourceWithURL:sourceURL];
//        NSOperation* downloadOp = [self downloadOperationForCatalogIndex:source];
        ZincRepoCatalogIndexUpdateOperation* downloadOp = [[[ZincRepoCatalogIndexUpdateOperation alloc] 
                                                            initWithClient:self source:source] autorelease];
        [self addOperationToPrimaryQueue:downloadOp];
        [parentOp addDependency:downloadOp];
    }
    [self addOperationToPrimaryQueue:parentOp];
}

- (NSArray*) sourcesForCatalogIdentifier:(NSString*)catalogId
{
    return [self.sourcesByCatalog objectForKey:catalogId];
}

#pragma mark Caching

- (NSString*) cacheKeyForCatalogIdentifier:(NSString*)identifier
{
    return [@"Catalog:" stringByAppendingString:identifier];
}

- (NSString*) cacheKeyManifestWithBundleIdentifier:(NSString*)identifier version:(ZincVersion)version
{
    return [[@"Manifest:" stringByAppendingString:identifier] stringByAppendingFormat:@"-%d", version];
}

- (NSString*) cacheKeyForBundleIdentifier:(NSString*)identifier version:(ZincVersion)version
{
    return [[@"Bundle:" stringByAppendingString:identifier] stringByAppendingFormat:@"-%d", version];
}

#pragma mark Catalogs

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
        NSString* key = [self cacheKeyForCatalogIdentifier:identifier];
        ZincCatalog* catalog = [self.cache objectForKey:key];
        if (catalog == nil) {
            catalog = [self loadCatalogWithIdentifier:identifier error:outError];
            if (catalog != nil) {
                [self.cache setObject:catalog forKey:key];
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

- (ZincManifest*) loadManifestWithBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError
{
    NSString* manifestPath = [self pathForManifestWithBundleIdentifier:bundleId version:version];
    NSString* jsonString = [NSString stringWithContentsOfFile:manifestPath encoding:NSUTF8StringEncoding error:outError];
    if (jsonString == nil) {
        return nil;
    }
    NSDictionary* jsonDict = [KSJSON deserializeString:jsonString error:outError];
    if (jsonDict == nil) {
        return nil;
    }
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:jsonDict] autorelease];
    return manifest;
}

- (ZincManifest*) manifestWithBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError
{
    @synchronized(self) {
        NSString* key = [self cacheKeyManifestWithBundleIdentifier:bundleId version:version];
        ZincManifest* manifest = [self.cache objectForKey:key];
        if (manifest == nil) {
            manifest = [self loadManifestWithBundleIdentifier:bundleId version:version error:outError];
            if (manifest != nil) {
                [self.cache setObject:manifest forKey:key];
            }
        }
        return manifest;
    }
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

- (void) beginTrackingBundleWithIdentifier:(NSString*)bundleId distribution:(NSString*)dist
{
    [self.trackedBundles setObject:dist forKey:bundleId];
    [self refreshSourcesWithCompletion:nil];
}

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion
{
    NSOperation* parentOp = [[[NSOperation alloc] init] autorelease];
    parentOp.completionBlock = completion;
    
    for (NSString* bundleId in [self.trackedBundles allKeys]) {
        NSString* label = [self.trackedBundles objectForKey:bundleId];
        ZincVersion version = [self versionForBundleIdentifier:bundleId label:label];
        
        ZincRepoEnsureBundleOperation* bundleOp = [[[ZincRepoEnsureBundleOperation alloc]
                                                    initWithClient:self bundleIdentifier:bundleId version:version]
                                                   autorelease];
        bundleOp = (ZincRepoEnsureBundleOperation*)[self addOperationToPrimaryQueue:bundleOp];
        [parentOp addDependency:bundleOp];
    }
    [self addOperationToPrimaryQueue:parentOp];
}

#pragma mark Bundle

- (ZincBundle*) bundleWithId:(NSString*)bundleId version:(ZincVersion)version
{
    NSString* descriptor = [ZincBundle descriptorForBundleId:bundleId version:version];
    ZincBundle* bundle = nil;
    
    @synchronized(self.loadedBundles) {
        bundle = [self.loadedBundles objectForKey:descriptor];
        
        if (bundle == nil) {
            bundle = [[[ZincBundle alloc] initWithBundleId:bundleId version:version repo:self] autorelease];

            NSError* error = nil;
            ZincManifest* manifest = [self manifestWithBundleIdentifier:bundleId version:version error:&error];
            if (manifest != nil) {
                bundle.manifest = manifest;
            }
            
            // TODO: handle error
            [self.loadedBundles setObject:bundle forKey:descriptor];
        }
    }
    
    return bundle;
}

- (ZincBundle*) bundleWithId:(NSString*)bundleId distribution:(NSString*)dist
{
    ZincVersion version = [self versionForBundleIdentifier:bundleId label:dist];
    if (version == ZincVersionInvalid) {
        return nil;
    }

    [self beginTrackingBundleWithIdentifier:bundleId distribution:dist];
    
    return [self bundleWithId:bundleId version:version];
}



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

@implementation ZincRepoAtomicFileWriteOperation

@synthesize data = _data;
@synthesize path = _path;

- (id)initWithClient:(ZincClient*)client data:(NSData*)data path:(NSString*)path
{
    self = [super initWithClient:client];
    if (self) {
        self.data = data;
        self.path = path;
    }
    return self;
}

- (void)dealloc
{
    self.path = nil;
    self.data = nil;
    [super dealloc];
}

- (void) main
{
    NSError* error = nil;
    
    NSString* dir = [self.path stringByDeletingLastPathComponent];
    if (![self.client.fileManager zinc_createDirectoryIfNeededAtPath:dir error:&error]) {
        self.error = error;
        return;
    }
    
    if (![self.client writeDataAtomically:self.data toPath:self.path error:&error]) {
        self.error = error;
        return;
    }
}

@end

// -----------------------------------------------------------------------------
#pragma mark - 

@implementation ZincRepoCatalogIndexUpdateOperation

@synthesize source = _source;

- (id)initWithClient:(ZincClient *)client source:(ZincSource*)source;
{
    self = [super initWithClient:client];
    if (self) {
        self.source = source;
    }
    return self;
}

- (void)dealloc
{
    self.source = nil;
    [super dealloc];
}

+ (NSString*) nameForSourceURL:(NSURL*)sourceURL
{
    return [NSString stringWithFormat:@"CatalogIndexUpdate:%@", [sourceURL absoluteString]];
}

- (NSString*) name
{
    return [[self class] nameForSourceURL:self.source.url];
}

- (void) main
{
    NSError* error = nil;
    
    NSURLRequest* request = [self.source urlRequestForCatalogIndex];
    AFHTTPRequestOperation* requestOp = [self.client queuedHTTPRequestOperationForRequest:request];
    [requestOp setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:200]];
    [requestOp waitUntilFinished];
    if (![requestOp hasAcceptableStatusCode]) {
        // TODO: error;
        return;
    }
    
    ZincCatalog* catalog = [ZincCatalog catalogFromJSONString:requestOp.responseString error:&error];
    if (catalog == nil) {
        self.error = error;
        return;
    }
    
    NSData* data = [[catalog jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        self.error = error;
        return;
    }
    
    NSString* path = [self.client pathForCatalogIndex:catalog];
    ZincRepoAtomicFileWriteOperation* writeOp = [self.client queuedAtomicFileWriteOperationForData:data path:path];
    [writeOp waitUntilFinished];
    if (writeOp.error != nil) {
        self.error = writeOp.error;
        return;
    } 
    
    [self.client registerSource:self.source forCatalog:catalog];
    
    [self.client.cache setObject:catalog forKey:[self.client cacheKeyForCatalogIdentifier:catalog.identifier]];
}

@end

// -----------------------------------------------------------------------------
#pragma mark - 

@implementation ZincRepoFileUpdateOperation

@synthesize source = _source;
@synthesize sha = _sha;

- (id)initWithClient:(ZincClient*)client source:(ZincSource*)souce sha:(NSString*)sha
{
    self = [super initWithClient:client];
    if (self) {
        self.source = souce;
        self.sha = sha;
    }
    return self;
}

- (void)dealloc
{
    self.source = nil;
    self.sha = nil;
    [super dealloc];
}

+ (NSString*) nameForSHA:(NSString*)sha
{
    return [NSString stringWithFormat:@"FileUpdate:%@", sha];
}

- (NSString*) name
{
    return [[self class] nameForSHA:self.sha];
}

- (void) main
{
    NSError* error = nil;
    
    NSURLRequest* request = [self.source urlRequestForFileWithSHA:self.sha];
    if (request == nil) {
        // TODO: better error
        NSAssert(0, @"request is nil");
        return;
    }
    
    NSString* path = [self.client pathForFileWithSHA:self.sha];
    NSString* dir = [path stringByDeletingLastPathComponent];
    
    if (![self.client.fileManager zinc_createDirectoryIfNeededAtPath:dir error:&error]) {
        self.error = error;
        return;
    }
    
    AFHTTPRequestOperation* downloadOp = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    downloadOp.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:200];
    
    NSOutputStream* outStream = [[[NSOutputStream alloc] initToFileAtPath:path append:NO] autorelease];
    downloadOp.outputStream = outStream;

    [self.client.networkOperationQueue addOperation:downloadOp];
    [downloadOp waitUntilFinished];
    
    if (!downloadOp.hasAcceptableStatusCode) {
        self.error = downloadOp.error;
    }
}

@end

// -----------------------------------------------------------------------------
#pragma mark - 

@implementation ZincRepoManifestUpdateOperation

@synthesize bundleId = _bundleId;
@synthesize version = _version;

- (id)initWithClient:(ZincClient *)client bundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
{
    self = [super initWithClient:client];
    if (self) {
        self.bundleId = bundleId;
        self.version = version;
    }
    return self;
}

- (void)dealloc
{
    self.bundleId = nil;
    [super dealloc];
}

+ (NSString*) nameForBundleId:(NSString*)bundleId version:(ZincVersion)version
{
    return [NSString stringWithFormat:@"ManifestUpdate:%@-%d", bundleId, version];
}

- (NSString*) name
{
    return [[self class] nameForBundleId:self.bundleId version:self.version];
}

- (void) main
{
    NSError* error = nil;
    
    NSString* catalogId = [ZincBundle sourceFromBundleIdentifier:self.bundleId];
    NSString* bundleName = [ZincBundle nameFromBundleIdentifier:self.bundleId];
    ZincSource* source = [[self.client sourcesForCatalogIdentifier:catalogId] lastObject]; // TODO: fix lastObject
    if (source == nil) {
        ZINC_DEBUG_LOG(@"source is nil");
        // TODO: better error
        return;
    }
    
    NSURLRequest* request = [source urlRequestForBundleName:bundleName version:self.version];
    if (request == nil) {
        // TODO: better error
        NSAssert(0, @"request is nil");
        return;
    }
    
    AFHTTPRequestOperation* requestOp = [self.client queuedHTTPRequestOperationForRequest:request];
    [requestOp setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:200]];
    [requestOp waitUntilFinished];
    if (!requestOp.hasAcceptableStatusCode) {
        self.error = requestOp.error;
        return;
    }
    
    id json = [KSJSON deserializeString:requestOp.responseString error:&error];
    if (json == nil) {
        //[self handleError:error];
        self.error = error;
        return;
    }
    
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:json] autorelease];
    NSData* data = [[manifest jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        //[blockself handleError:error];
        self.error = error;
        return;
    }
    
    NSString* path = [self.client pathForManifestWithBundleIdentifier:self.bundleId version:manifest.version];
    ZincRepoAtomicFileWriteOperation* writeOp = [self.client queuedAtomicFileWriteOperationForData:data path:path];
    [writeOp waitUntilFinished];
    if (writeOp.error != nil) {
        //[blockself handleError:writeOp.error];
        self.error = error;
        return;
    }
    
    NSString* cacheKey = [self.client cacheKeyManifestWithBundleIdentifier:self.bundleId version:self.version];
    [self.client.cache setObject:manifest forKey:cacheKey];
}

@end

// -----------------------------------------------------------------------------
#pragma mark - 

@implementation ZincRepoEnsureBundleOperation

@synthesize bundleId = _bundleId;
@synthesize version = _version;

- (id)initWithClient:(ZincClient *)client bundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
{
    self = [super initWithClient:client];
    if (self) {
        self.bundleId = bundleId;
        self.version = version;
    }
    return self;
}

- (void)dealloc
{
    self.bundleId = nil;
    [super dealloc];
}

+ (NSString*) nameForBundleId:(NSString*)bundleId version:(ZincVersion)version
{
    return [NSString stringWithFormat:@"BundleUpdate:%@-%d", bundleId, version];
}

- (NSString*) name
{
    return [[self class] nameForBundleId:self.bundleId version:self.version];
}

- (void) main
{
    NSError* error = nil;
    
    NSString* manifestUpdateName = [ZincRepoManifestUpdateOperation nameForBundleId:self.bundleId version:self.version];
    ZincOperation* manifestOp = [self.client getOperationWithName:manifestUpdateName];
    if (manifestOp == nil) {
        if (![self.client hasManifestForBundleIdentifier:self.bundleId version:self.version]) {
            manifestOp = [[[ZincRepoManifestUpdateOperation alloc] initWithClient:self.client bundleIdentifier:self.bundleId version:self.version] autorelease];
            manifestOp = (ZincOperation*)[self.client addOperationToPrimaryQueue:manifestOp];
        }
    }
    
    if (manifestOp != nil) {
        [manifestOp waitUntilFinished];
        if (manifestOp.error != nil) {
            self.error = manifestOp.error;
            return;
        }
    }
    
    ZincManifest* manifest = [self.client manifestWithBundleIdentifier:self.bundleId version:self.version error:&error];
    if (manifest == nil) {
        self.error = error;
        return;
    }
    
    NSArray* SHAs = [manifest allSHAs];
    NSMutableArray* fileOps = [NSMutableArray arrayWithCapacity:[SHAs count]];
    
    for (NSString* expectedSHA in SHAs) {
        NSString* path = [self.client pathForFileWithSHA:expectedSHA];
        NSString* actualSHA = [self.client.fileManager zinc_sha1ForPath:path];
        
        // check if file is missing or invalid
        if (actualSHA == nil || ![expectedSHA isEqualToString:actualSHA]) {
            
            // queue redownload
            NSString* catalogId = [ZincBundle sourceFromBundleIdentifier:self.bundleId];
            ZincSource* source = [[self.client sourcesForCatalogIdentifier:catalogId] lastObject]; // fix lastObject
            NSOperation* op = 
            [[[ZincRepoFileUpdateOperation alloc] initWithClient:self.client
                                                          source:source
                                                             sha:expectedSHA] autorelease];
            op = [self.client addOperationToPrimaryQueue:op];
            [fileOps addObject:op];
        }
    }

    NSMutableArray* errors = [NSMutableArray array];
    for (ZincOperation* op in fileOps) {
        [op waitUntilFinished];
        if (op.error != nil) {
            [errors addObject:error];
        }
    }
    
    if ([errors count] == 0) {
        
        ZINC_DEBUG_LOG(@"AMAZING!");
    }
}


@end



