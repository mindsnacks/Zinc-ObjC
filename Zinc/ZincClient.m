//
//  ZCBundleManager.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincClient.h"
#import "ZincClient+Private.h"
#import "ZincBundle.h"
#import "ZincManifest.h"
#import "ZincBundle+Private.h"
#import "NSFileManager+Zinc.h"
#import "ZincSource.h"
#import "ZincCatalog.h"
#import "ZincEvent.h"
//#import "ZincOperation+Private.h"
#import "KSJSON.h"
#import "AFNetworking.h"
#import "sha1.h"
#import "MAWeakDictionary.h"
#import "NSData+Zinc.h"

#import "ZincAtomicFileWriteOperation.h"
#import "ZincBundleUpdateOperation.h"
#import "ZincCatalogUpdateOperation2.h"

#define CATALOGS_DIR_NAME @"catalogs"
#define MANIFESTS_DIR_NAME @"manifests"
#define FILES_DIR_NAME @"files"
#define BUNDLES_DIR_NAME @"bundles"

static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";

static ZincClient* _defaultClient = nil;

@interface ZincClient ()
@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSOperationQueue* networkQueue;
@property (nonatomic, retain) NSOperationQueue* fileWriteQueue;
@property (nonatomic, retain) NSOperationQueue* bundleUpdateQueue;
@property (nonatomic, retain) NSOperationQueue* defaultQueue;

@property (nonatomic, retain) NSMutableDictionary* operationsByName;
@property (nonatomic, retain) NSMutableSet* sourceURLs;
@property (nonatomic, retain) NSMutableDictionary* sourcesByCatalog;
@property (nonatomic, retain) NSMutableDictionary* trackedBundles;
@property (nonatomic, retain) NSCache* cache;
@property (nonatomic, retain) NSFileManager* fileManager;
@property (nonatomic, retain) NSTimer* refreshTimer;
@property (nonatomic, retain) MAWeakDictionary* loadedBundles;

@property (nonatomic, retain) NSMutableArray* myTasks;

- (BOOL) createDirectoriesIfNeeded:(NSError**)outError;
- (NSString*) catalogsPath;
- (NSString*) manifestsPath;
- (NSString*) filesPath;
- (NSString*) bundlesPath;

- (NSString*) cacheKeyForCatalogIdentifier:(NSString*)identifier;
- (NSString*) cacheKeyManifestWithBundleIdentifier:(NSString*)identifier version:(ZincVersion)version;
- (NSString*) cacheKeyForBundleIdentifier:(NSString*)identifier version:(ZincVersion)version;

- (void) registerSource:(ZincSource*)source forCatalog:(ZincCatalog*)catalog;
- (NSArray*) sourcesForCatalogIdentifier:(NSString*)catalogId;

- (ZincCatalog*) catalogWithIdentifier:(NSString*)source error:(NSError**)outError;
- (ZincVersion) versionForBundleIdentifier:(NSString*)bundleId label:(NSString*)label;

- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
- (ZincManifest*) manifestWithBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError;

@end

//@interface ZincRepoAtomicFileWriteOperation : ZincOperation
//- (id)initWithClient:(ZincClient*)client data:(NSData*)data path:(NSString*)path;
//@property (nonatomic, retain) NSData* data;
//@property (nonatomic, retain) NSString* path;
//@end
//
////@interface ZincRepoGzipInflateOperation : ZincOperation
////@end
//
//@interface ZincRepoCatalogIndexUpdateOperation : ZincOperation
//- (id)initWithClient:(ZincClient *)client source:(ZincSource*)source;
//@property (nonatomic, retain) ZincSource* source;
//@end
//
//@interface ZincRepoFileUpdateOperation : ZincOperation
//- (id)initWithClient:(ZincClient*)client source:(ZincSource*)souce sha:(NSString*)sha;
//@property (nonatomic, retain) ZincSource* source;
//@property (nonatomic, retain) NSString* sha;
//@end
//
//@interface ZincRepoManifestUpdateOperation : ZincOperation
//- (id)initWithClient:(ZincClient *)client bundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
//+ (NSString*) nameForBundleId:(NSString*)bundleId version:(ZincVersion)version;
//@property (nonatomic, retain) NSString* bundleId;
//@property (nonatomic, assign) ZincVersion version;
//@end
//
//@interface ZincRepoEnsureBundleOperation : ZincOperation
//- (id)initWithClient:(ZincClient *)client bundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
//@property (nonatomic, retain) NSString* bundleId;
//@property (nonatomic, assign) ZincVersion version;
//@end

@implementation ZincClient

@synthesize delegate = _delegate;
@synthesize url = _url;
@synthesize networkQueue = _networkQueue;
@synthesize defaultQueue = _defaultQueue;
@synthesize fileWriteQueue = _fileWriteQueue;
@synthesize bundleUpdateQueue = _bundleUpdateQueue;
@synthesize operationsByName = _operationsByName;
@synthesize sourceURLs = _sourceURLs;
@synthesize sourcesByCatalog = _sourcesByCatalog;
@synthesize trackedBundles = _trackedBundles;
@synthesize fileManager = _fileManager;
@synthesize cache = _cache;
@synthesize refreshInterval = _refreshInterval;
@synthesize refreshTimer = _refreshTimer;
@synthesize loadedBundles = _loadedBundles;
@synthesize myTasks = _myTasks;

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
        self.defaultQueue = [[[NSOperationQueue alloc] init] autorelease];
        self.defaultQueue.maxConcurrentOperationCount = 5;
        self.fileWriteQueue = [[[NSOperationQueue alloc] init] autorelease];
        self.fileWriteQueue.maxConcurrentOperationCount = 1;
        self.networkQueue = operationQueue;
        self.bundleUpdateQueue = [[[NSOperationQueue alloc] init] autorelease];
        self.bundleUpdateQueue.maxConcurrentOperationCount = 2;
        self.operationsByName = [NSMutableDictionary dictionary];
        self.sourceURLs = [NSMutableSet set];
        self.sourcesByCatalog = [NSMutableDictionary dictionary];
        self.trackedBundles = [NSMutableDictionary dictionary];
        self.fileManager = [[[NSFileManager alloc] init] autorelease];
        self.cache = [[[NSCache alloc] init] autorelease];
        self.refreshInterval = 5.0;
        self.loadedBundles = [NSMutableDictionary dictionary];
        self.myTasks = [NSMutableArray array];
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
        
//        [blockself refreshBundlesWithCompletion:^{
//            
//        }];
    }];
    
    [blockself refreshBundlesWithCompletion:^{
        
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
    self.defaultQueue = nil;
    self.fileWriteQueue = nil;
    self.networkQueue = nil;
    self.bundleUpdateQueue = nil;
    self.sourceURLs = nil;
    self.sourcesByCatalog = nil;
    self.trackedBundles = nil;
    self.cache = nil;
    self.loadedBundles = nil;
    self.myTasks = nil;
    
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
    if (![self.fileManager zinc_createDirectoryIfNeededAtPath:[self bundlesPath] error:outError]) {
        return NO;
    }
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

- (NSString*) bundlesPath
{
    return [[self.url path] stringByAppendingPathComponent:BUNDLES_DIR_NAME];
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

- (void) handleError:(NSError*)error
{
    __block typeof(self) blockself = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        ZINC_DEBUG_LOG(@"[ZincClient 0x%x] %@", (int)blockself, error);
        
        ZincErrorEvent* errorEvent = [[[ZincErrorEvent alloc] initWithError:error source:blockself] autorelease];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZincEventNotification object:errorEvent];
        
        [blockself.delegate zincClient:blockself didEncounterError:error];
    }];
}

//- (ZincOperation*) getOperationWithDescriptor:(NSString*)name
//{
//    @synchronized(self) {
//
//        //        NSArray* matching = [[self.defaultQueue operations]
////                             filteredArrayUsingPredicate:
////                             [NSPredicate predicateWithFormat:@"name == %@", name]];
////        if (matching != nil && [matching count] > 0) {
////            return [matching objectAtIndex:0];
////        }
////        return nil;
//        
//        for (NSOperation* op in [self.defaultQueue operations]) {
//            ZincOperation* zop = (ZincOperation*)op;
//            if ([name isEqualToString:zop.descriptor]) {
//                return zop;
//            }
//        }
//        return nil;
//    }
//}

//- (ZincOperation*) addOperationToPrimaryQueue:(ZincOperation*)operation
//{
//    @synchronized(self) {
//        NSString* descriptor = [operation valueForKey:@"descriptor"];
//        if (descriptor != nil) {
//            ZincOperation* existing = [self getOperationWithDescriptor:descriptor];
//            if (existing != nil) {
//                return existing;
//            }
//        }
//        
//        __block typeof(self) blockself = self;
//        operation.completionBlock = ^{
//            if (operation.error != nil) {
//                [blockself handleError:operation.error];
//            }
//        };
//        
//        [self.defaultQueue addOperation:operation];
//        return operation;
//    }
//}

- (void) addOperation:(NSOperation*)operation
{
//    if ([operation isKindOfClass:[ZincRepoAtomicFileWriteOperation class]]) {
//        [self.fileWriteQueue addOperation:operation];
        
   if ([operation isKindOfClass:[ZincAtomicFileWriteOperation class]]) {
        [self.fileWriteQueue addOperation:operation];
        
    } else if ([operation isKindOfClass:[AFURLConnectionOperation class]]) {
        [self.networkQueue addOperation:operation];
        
    } else if ([operation isKindOfClass:[ZincBundleUpdateOperation class]]) {
        [self.bundleUpdateQueue addOperation:operation];
        
    } else {
        [self.defaultQueue addOperation:operation];
    }
}

//- (ZincOperation*) queuedAtomicFileWriteOperationForData:(NSData*)data path:(NSString*)path
//{
//    ZincRepoAtomicFileWriteOperation* op = [[[ZincRepoAtomicFileWriteOperation alloc] initWithClient:self data:data path:path] autorelease];
//    [self.fileWriteQueue addOperation:op];
//    return op;
//}

//- (AFHTTPRequestOperation*) queuedHTTPRequestOperationForRequest:(NSURLRequest*)request
//{
//    AFHTTPRequestOperation* op = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
//    [self.networkQueue addOperation:op];
//    ZINC_DEBUG_LOG(@"[ZincClient 0x%x] Downloading %@", (int)self, [request URL]);
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
        [self.cache setObject:catalog forKey:[self cacheKeyForCatalogIdentifier:catalog.identifier]];
    }
}

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion
{
//    NSOperation* parentOp = [[[NSOperation alloc] init] autorelease];
//    parentOp.completionBlock = completion;
    
    for (NSURL* sourceURL in self.sourceURLs) {
        ZincSource* source = [ZincSource sourceWithURL:sourceURL];
//        ZincRepoCatalogIndexUpdateOperation* catalogOp = [[[ZincRepoCatalogIndexUpdateOperation alloc] 
//                                                            initWithClient:self source:source] autorelease];
//        [self addOperation:catalogOp];

        ZincCatalogUpdateOperation2* catalogOp = [[[ZincCatalogUpdateOperation2 alloc] initWithClient:self source:source] autorelease];
        [self getOrAddTask:catalogOp];
        
//        [self addOperationToPrimaryQueue:downloadOp];
//        [parentOp addDependency:downloadOp];
    }
//    [self addOperationToPrimaryQueue:parentOp];
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

- (void) registerManifest:(ZincManifest*)manifest forBundleId:(NSString*)bundleId
{
    NSString* cacheKey = [self cacheKeyManifestWithBundleIdentifier:bundleId version:manifest.version];
    [self.cache setObject:manifest forKey:cacheKey];
}

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

//- (NSArray*) activeBundles
//{
//    // TODO: synchronized?
//    
//    NSMutableArray* activeBundles = [NSMutableArray array];
//    
//    for (NSString* bundleId in self.trackedBundles) {
//        NSString* dist = [self.trackedBundles objectForKey:bundleId];
//        ZincVersion version = [self versionForBundleIdentifier:bundleId label:dist];
//        [activeBundles addObject:[ZincBundle descriptorForBundleId:bundleId version:version]];
//    }
//    
//    NSArray* loadedBundlesIds = [self.loadedBundles allKeys];
//    for (NSString* bundleId in loadedBundlesIds) {
//        
//    }
//}

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
    [self refreshBundlesWithCompletion:nil];
}

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion
{
//    NSOperation* parentOp = [[[NSOperation alloc] init] autorelease];
//    parentOp.completionBlock = completion;
    
    for (NSString* bundleId in [self.trackedBundles allKeys]) {
        NSString* label = [self.trackedBundles objectForKey:bundleId];
        ZincVersion version = [self versionForBundleIdentifier:bundleId label:label];
        if (version != ZincVersionInvalid) {
            
//            ZincRepoEnsureBundleOperation* bundleOp = [[[ZincRepoEnsureBundleOperation alloc]
//                                                        initWithClient:self bundleIdentifier:bundleId version:version]
//                                                       autorelease];
//           // bundleOp = (ZincRepoEnsureBundleOperation*)[self addOperationToPrimaryQueue:bundleOp];
//            [self addOperation:bundleOp];
            
            ZincBundleUpdateOperation* bundleOp = [[[ZincBundleUpdateOperation alloc]
                                                    initWithClient:self bundleIdentifier:bundleId version:version]
                                                   autorelease];
            [self getOrAddTask:bundleOp];
        }
//        [parentOp addDependency:bundleOp];
    }
//    [self addOperationToPrimaryQueue:parentOp];
}

#pragma mark Bundles

- (NSString*) pathForBundleWithId:(NSString*)bundleId version:(ZincVersion)version
{
    NSString* bundleDirName = [NSString stringWithFormat:@"%@-%d", bundleId, version];
    NSString* bundlePath = [[self bundlesPath] stringByAppendingPathComponent:bundleDirName];
    return bundlePath;
}

- (NSBundle*) bundleWithId:(NSString*)bundleId version:(ZincVersion)version
{
    NSString* descriptor = [ZincBundle descriptorForBundleId:bundleId version:version];
    NSBundle* bundle = nil;
    
    @synchronized(self.loadedBundles) {
        bundle = [self.loadedBundles objectForKey:descriptor];
        
        if (bundle == nil) {
            
            bundle = [[[NSBundle alloc] initWithPath:[self pathForBundleWithId:bundleId version:version]] autorelease];
            if (bundle == nil) return nil;
            
            // TODO: handle error
            [self.loadedBundles setObject:bundle forKey:descriptor];
        }
    }
    return bundle;
}

- (NSBundle*) bundleWithId:(NSString*)bundleId distribution:(NSString*)dist
{
    [self beginTrackingBundleWithIdentifier:bundleId distribution:dist];

    ZincVersion version = [self versionForBundleIdentifier:bundleId label:dist];
    if (version == ZincVersionInvalid) {
        return nil;
    }
    
    return [self bundleWithId:bundleId version:version];
}

#pragma mark Tasks

- (NSArray*) tasks
{
    return [NSArray arrayWithArray:self.myTasks];
}

- (ZincTask2*) taskForKey:(NSString*)key
{
    @synchronized(self.myTasks) {
        for (ZincTask2* task in self.myTasks) {
            if ([[task key] isEqualToString:key]) {
                return task;
            }
        }
    }
    return nil;
}

- (ZincTask2*) getOrAddTask:(ZincTask2*)task
{
    @synchronized(self.myTasks) {
        ZincTask2* existingTask = [self taskForKey:[task key]];
        
        if (existingTask == nil) {
            [self.myTasks addObject:task];
            [task addObserver:self forKeyPath:@"isFinished" options:0 context:&kvo_taskIsFinished];
            [self addOperation:task];
            return task;
            
        } else {
            return existingTask;
        }
    }
}

-  (void) removeTask:(ZincTask2*)task
{
    @synchronized(self.myTasks) {
        ZincTask2* foundTask = [self taskForKey:[task key]];
        if (foundTask != nil) {
            [foundTask removeObserver:self forKeyPath:@"isFinished"];
            [self.myTasks removeObject:foundTask];
        }
    }
}

//- (ZincBundle*) bundleWithId:(NSString*)bundleId version:(ZincVersion)version
//{
//    NSString* descriptor = [ZincBundle descriptorForBundleId:bundleId version:version];
//    ZincBundle* bundle = nil;
//    
//    @synchronized(self.loadedBundles) {
//        bundle = [self.loadedBundles objectForKey:descriptor];
//        
//        if (bundle == nil) {
//            bundle = [[[ZincBundle alloc] initWithBundleId:bundleId version:version repo:self] autorelease];
//
//            NSError* error = nil;
//            ZincManifest* manifest = [self manifestWithBundleIdentifier:bundleId version:version error:&error];
//            if (manifest != nil) {
//                bundle.manifest = manifest;
//            }
//            
//            // TODO: handle error
//            [self.loadedBundles setObject:bundle forKey:descriptor];
//        }
//    }
//    
//    return bundle;
//}
//
//- (ZincBundle*) bundleWithId:(NSString*)bundleId distribution:(NSString*)dist
//{
//    ZincVersion version = [self versionForBundleIdentifier:bundleId label:dist];
//    if (version == ZincVersionInvalid) {
//        return nil;
//    }
//
//    [self beginTrackingBundleWithIdentifier:bundleId distribution:dist];
//    
//    return [self bundleWithId:bundleId version:version];
//}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &kvo_taskIsFinished) {
        ZincTask2* task = (ZincTask2*)object;
        if (task.isFinished) {
            [self removeTask:task];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

//// -----------------------------------------------------------------------------
//#pragma mark - 
//
//@implementation ZincRepoAtomicFileWriteOperation
//
//@synthesize data = _data;
//@synthesize path = _path;
//
//- (id)initWithClient:(ZincClient*)client data:(NSData*)data path:(NSString*)path
//{
//    self = [super initWithClient:client];
//    if (self) {
//        self.data = data;
//        self.path = path;
//    }
//    return self;
//}
//
//- (void)dealloc
//{
//    self.path = nil;
//    self.data = nil;
//    [super dealloc];
//}
//
//- (void) main
//{
//    NSError* error = nil;
//    
//    NSString* dir = [self.path stringByDeletingLastPathComponent];
//    if (![self.client.fileManager zinc_createDirectoryIfNeededAtPath:dir error:&error]) {
//        self.error = error;
//        return;
//    }
//    
//    if (![self.data zinc_writeToFile:self.path atomically:YES skipBackup:YES error:&error]) {
//        self.error = error;
//        return;
//    }
//}
//
//@end
//
//// -----------------------------------------------------------------------------
//#pragma mark - 
//
//@implementation ZincRepoCatalogIndexUpdateOperation
//
//@synthesize source = _source;
//
//- (id)initWithClient:(ZincClient *)client source:(ZincSource*)source;
//{
//    self = [super initWithClient:client];
//    if (self) {
//        self.source = source;
//    }
//    return self;
//}
//
//- (void)dealloc
//{
//    self.source = nil;
//    [super dealloc];
//}
//
//+ (NSString*) nameForSourceURL:(NSURL*)sourceURL
//{
//    return [NSString stringWithFormat:@"CatalogIndexUpdate:%@", [sourceURL absoluteString]];
//}
//
//- (NSString*) descriptor
//{
//    return [[self class] nameForSourceURL:self.source.url];
//}
//
//- (void) main
//{
//    NSError* error = nil;
//    
//    NSURLRequest* request = [self.source urlRequestForCatalogIndex];
//    AFHTTPRequestOperation* requestOp = [self.client queuedHTTPRequestOperationForRequest:request];
//    [requestOp setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:200]];
//    [requestOp waitUntilFinished];
//    if (![requestOp hasAcceptableStatusCode]) {
//        // TODO: error;
//        return;
//    }
//    
//    NSData* uncompressed = [requestOp.responseData zinc_gzipInflate];
//    if (uncompressed == nil) {
//        // TODO: real error
//        NSAssert(NO, @"gunzip failed");
//        return;
//    }
//    
//    NSString* jsonString = [[[NSString alloc] initWithData:uncompressed encoding:NSUTF8StringEncoding] autorelease];
//    ZincCatalog* catalog = [ZincCatalog catalogFromJSONString:jsonString error:&error];
//    if (catalog == nil) {
//        self.error = error;
//        return;
//    }
//    
//    NSData* data = [[catalog jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
//    if (data == nil) {
//        self.error = error;
//        return;
//    }
//    
//    NSString* path = [self.client pathForCatalogIndex:catalog];
//    ZincOperation* writeOp = [self.client queuedAtomicFileWriteOperationForData:data path:path];
//    [writeOp waitUntilFinished];
//    if (writeOp.error != nil) {
//        self.error = writeOp.error;
//        return;
//    } 
//    
//    [self.client registerSource:self.source forCatalog:catalog];
//    
//    [self.client.cache setObject:catalog forKey:[self.client cacheKeyForCatalogIdentifier:catalog.identifier]];
//}
//
//@end
//
//// -----------------------------------------------------------------------------
//#pragma mark - 
//
//@implementation ZincRepoFileUpdateOperation
//
//@synthesize source = _source;
//@synthesize sha = _sha;
//
//- (id)initWithClient:(ZincClient*)client source:(ZincSource*)souce sha:(NSString*)sha
//{
//    self = [super initWithClient:client];
//    if (self) {
//        self.source = souce;
//        self.sha = sha;
//    }
//    return self;
//}
//
//- (void)dealloc
//{
//    self.source = nil;
//    self.sha = nil;
//    [super dealloc];
//}
//
//+ (NSString*) nameForSHA:(NSString*)sha
//{
//    return [NSString stringWithFormat:@"FileUpdate:%@", sha];
//}
//
//- (NSString*) descriptor
//{
//    return [[self class] nameForSHA:self.sha];
//}
//
//- (void) main
//{
//    NSError* error = nil;
//    BOOL gz = NO;
//    
//    NSString* ext = nil;
//    if (gz) {
//        ext = @"gz";
//    }
//    
//    //NSURLRequest* request = [self.source urlRequestForFileWithSHA:self.sha];
//    NSURLRequest* request = [self.source urlRequestForFileWithSHA:self.sha extension:ext];
//    if (request == nil) {
//        // TODO: better error
//        NSAssert(0, @"request is nil");
//        return;
//    }
//    
//    NSString* path = [self.client pathForFileWithSHA:self.sha];
//    NSString* gzpath = [path stringByAppendingPathExtension:@"gz"];
//    NSString* dir = [gzpath stringByDeletingLastPathComponent];
//    NSString* downloadPath = path;
//    if (gz) {
//        downloadPath = gzpath;
//    }
//    
//    if (![self.client.fileManager zinc_createDirectoryIfNeededAtPath:dir error:&error]) {
//        self.error = error;
//        return;
//    }
//    
//    AFHTTPRequestOperation* downloadOp = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
//    downloadOp.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:200];
//    
////    NSOutputStream* outStream = [[[NSOutputStream alloc] initToFileAtPath:gzpath append:NO] autorelease];
//    NSOutputStream* outStream = [[[NSOutputStream alloc] initToFileAtPath:downloadPath append:NO] autorelease];
//    downloadOp.outputStream = outStream;
//    
//    ZINC_DEBUG_LOG(@"[ZincClient 0x%x] Downloading %@", (int)self.client, [request URL]);
//
//    [self.client.networkQueue addOperation:downloadOp];    
//    [downloadOp waitUntilFinished];
//    
//    if (!downloadOp.hasAcceptableStatusCode) {
//        self.error = downloadOp.error;
//        return;
//    }
//
//    if (gz) {
//        NSData* compressed = [[[NSData alloc] initWithContentsOfFile:gzpath] autorelease];
//        NSData* uncompressed = [compressed zinc_gzipInflate];
//        if (![uncompressed writeToFile:path options:0 error:&error]) {
//            self.error = error;
//            // don't return! remove the gz file
//        }
//        [self.client.fileManager removeItemAtPath:gzpath error:NULL];
//    }
//}
//
//@end
//
//// -----------------------------------------------------------------------------
//#pragma mark - 
//
//@implementation ZincRepoManifestUpdateOperation
//
//@synthesize bundleId = _bundleId;
//@synthesize version = _version;
//
//- (id)initWithClient:(ZincClient *)client bundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
//{
//    self = [super initWithClient:client];
//    if (self) {
//        self.bundleId = bundleId;
//        self.version = version;
//    }
//    return self;
//}
//
//- (void)dealloc
//{
//    self.bundleId = nil;
//    [super dealloc];
//}
//
//+ (NSString*) nameForBundleId:(NSString*)bundleId version:(ZincVersion)version
//{
//    return [NSString stringWithFormat:@"ManifestUpdate:%@-%d", bundleId, version];
//}
//
//- (NSString*) descriptor
//{
//    return [[self class] nameForBundleId:self.bundleId version:self.version];
//}
//
//- (void) main
//{
//    NSError* error = nil;
//    
//    NSString* catalogId = [ZincBundle sourceFromBundleIdentifier:self.bundleId];
//    NSString* bundleName = [ZincBundle nameFromBundleIdentifier:self.bundleId];
//    ZincSource* source = [[self.client sourcesForCatalogIdentifier:catalogId] lastObject]; // TODO: fix lastObject
//    if (source == nil) {
//        ZINC_DEBUG_LOG(@"source is nil");
//        // TODO: better error
//        return;
//    }
//    
//    NSURLRequest* request = [source urlRequestForBundleName:bundleName version:self.version];
//    if (request == nil) {
//        // TODO: better error
//        NSAssert(0, @"request is nil");
//        return;
//    }
//    
//    AFHTTPRequestOperation* requestOp = [self.client queuedHTTPRequestOperationForRequest:request];
//    [requestOp setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:200]];
//    [requestOp waitUntilFinished];
//    if (!requestOp.hasAcceptableStatusCode) {
//        self.error = requestOp.error;
//        return;
//    }
//    
//    NSData* uncompressed = [requestOp.responseData zinc_gzipInflate];
//    if (uncompressed == nil) {
//        // TODO: set error
//        NSAssert(NO, @"gunzip failed");
//        return;
//    }
//    
//    NSString* jsonString = [[[NSString alloc] initWithData:uncompressed encoding:NSUTF8StringEncoding] autorelease];
//    id json = [KSJSON deserializeString:jsonString error:&error];
//    if (json == nil) {
//        //[self handleError:error];
//        self.error = error;
//        return;
//    }
//    
//    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:json] autorelease];
//    NSData* data = [[manifest jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
//    if (data == nil) {
//        //[blockself handleError:error];
//        self.error = error;
//        return;
//    }
//    
//    NSString* path = [self.client pathForManifestWithBundleIdentifier:self.bundleId version:manifest.version];
//    ZincOperation* writeOp = [self.client queuedAtomicFileWriteOperationForData:data path:path];
//    [writeOp waitUntilFinished];
//    if (writeOp.error != nil) {
//        //[blockself handleError:writeOp.error];
//        self.error = error;
//        return;
//    }
//    
//    NSString* cacheKey = [self.client cacheKeyManifestWithBundleIdentifier:self.bundleId version:self.version];
//    [self.client.cache setObject:manifest forKey:cacheKey];
//}
//
//@end
//
//// -----------------------------------------------------------------------------
//#pragma mark - 
//
//@implementation ZincRepoEnsureBundleOperation
//
//@synthesize bundleId = _bundleId;
//@synthesize version = _version;
//
//- (id)initWithClient:(ZincClient *)client bundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
//{
//    self = [super initWithClient:client];
//    if (self) {
//        self.bundleId = bundleId;
//        self.version = version;
//    }
//    return self;
//}
//
//- (void)dealloc
//{
//    self.bundleId = nil;
//    [super dealloc];
//}
//
//+ (NSString*) nameForBundleId:(NSString*)bundleId version:(ZincVersion)version
//{
//    return [NSString stringWithFormat:@"BundleUpdate:%@-%d", bundleId, version];
//}
//
//- (NSString*) descriptor
//{
//    return [[self class] nameForBundleId:self.bundleId version:self.version];
//}
//
//- (void) main
//{
//    ZINC_DEBUG_LOG(@"ENSURING BUNDLE %@!", self.bundleId);
//
//    NSError* error = nil;
//    
//    NSString* manifestUpdateName = [ZincRepoManifestUpdateOperation nameForBundleId:self.bundleId version:self.version];
//    ZincOperation* manifestOp = [self.client getOperationWithDescriptor:manifestUpdateName];
//    if (manifestOp == nil) {
//        if (![self.client hasManifestForBundleIdentifier:self.bundleId version:self.version]) {
//            manifestOp = [[[ZincRepoManifestUpdateOperation alloc] initWithClient:self.client bundleIdentifier:self.bundleId version:self.version] autorelease];
//            //manifestOp = (ZincOperation*)[self.client addOperationToPrimaryQueue:manifestOp];
//            [self.client addOperation:manifestOp];
//        }
//    }
//    
//    if (manifestOp != nil) {
//        [manifestOp waitUntilFinished];
//        if (manifestOp.error != nil) {
//            self.error = manifestOp.error;
//            return;
//        }
//    }
//    
//    ZincManifest* manifest = [self.client manifestWithBundleIdentifier:self.bundleId version:self.version error:&error];
//    if (manifest == nil) {
//        self.error = error;
//        return;
//    }
//    
//    NSString* catalogId = [ZincBundle sourceFromBundleIdentifier:self.bundleId];
//    NSArray* sources = [self.client sourcesForCatalogIdentifier:catalogId];
//    if (sources == nil || [sources count] == 0) {
//        // TODO: error, log, or requeue or SOMETHING
//        return;
//    }
//    
//    NSArray* SHAs = [manifest allSHAs];
//    NSMutableArray* fileOps = [NSMutableArray arrayWithCapacity:[SHAs count]];
//    
//    for (NSString* expectedSHA in SHAs) {
//        NSString* path = [self.client pathForFileWithSHA:expectedSHA];
//        NSString* actualSHA = [self.client.fileManager zinc_sha1ForPath:path];
//        
//        // check if file is missing or invalid
//        if (actualSHA == nil || ![expectedSHA isEqualToString:actualSHA]) {
//            
//            // queue redownload
//            ZincSource* source = [sources lastObject]; // TODO: fix lastobject
//            NSAssert(source, @"source is nil");
//            ZincOperation* fileOp = 
//            [[[ZincRepoFileUpdateOperation alloc] initWithClient:self.client
//                                                          source:source
//                                                             sha:expectedSHA] autorelease];
////            op = [self.client addOperationToPrimaryQueue:op];
//            [self.client addOperation:fileOp];
//            [fileOps addObject:fileOp];
//        }
//    }
//
//    NSMutableArray* errors = [NSMutableArray array];
//    for (ZincOperation* op in fileOps) {
//        [op waitUntilFinished];
//        if (op.error != nil) {
//            [errors addObject:op.error];
//        }
//    }
//    
//    NSString* bundlePath = [self.client pathForBundleWithId:self.bundleId version:self.version];
//    NSArray* allFiles = [manifest allFiles];
//    for (NSString* file in allFiles) {
//        NSString* filePath = [bundlePath stringByAppendingPathComponent:file];
//        NSString* fileDir = [filePath stringByDeletingLastPathComponent];
//        if (![self.client.fileManager zinc_createDirectoryIfNeededAtPath:fileDir error:&error]) {
//            self.error = error;
//            return;
//        }
//        
//        NSString* shaPath = [self.client pathForFileWithSHA:[manifest shaForFile:file]];
//        BOOL createLink = NO;
//        if ([self.client.fileManager fileExistsAtPath:filePath]) {
//            NSString* dst = [self.client.fileManager destinationOfSymbolicLinkAtPath:filePath error:NULL];
//            if (![dst isEqualToString:shaPath]) {
//                if (![self.client.fileManager removeItemAtPath:filePath error:&error]) {
//                    self.error = error;
//                    return;
//                }
//                createLink = YES;
//            }
//        } else {
//            createLink = YES;
//        }
//
//        if (createLink) {
//            if (![self.client.fileManager createSymbolicLinkAtPath:filePath withDestinationPath:shaPath error:&error]) {
//                self.error = error;
//                return;
//            }
//        }
//    }
//    
//    if ([errors count] == 0) {
//        
//        ZINC_DEBUG_LOG(@"FINISHED BUNDLE %@!", self.bundleId);
//    }
//}
//
//
//@end



