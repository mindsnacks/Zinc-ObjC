//
//  ZCBundleManager.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincBundle.h"
#import "ZincManifest.h"
#import "ZincBundle+Private.h"
#import "NSFileManager+Zinc.h"
#import "ZincSource.h"
#import "ZincCatalog.h"
#import "ZincEvent.h"
#import "KSJSON.h"
#import "AFNetworking.h"
#import "MAWeakDictionary.h"
#import "NSData+Zinc.h"

#import "ZincAtomicFileWriteOperation.h"
#import "ZincBundleUpdateTask.h"
#import "ZincCatalogUpdateTask.h"

#define CATALOGS_DIR_NAME @"catalogs"
#define MANIFESTS_DIR_NAME @"manifests"
#define FILES_DIR_NAME @"files"
#define BUNDLES_DIR_NAME @"bundles"

static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";

@interface ZincRepo ()
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

@implementation ZincRepo

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

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL error:(NSError**)outError
{
    ZincRepo* repo = [[[ZincRepo alloc] initWithURL:fileURL] autorelease];
    if (![repo createDirectoriesIfNeeded:outError]) {
        return nil;
    }
    return repo;
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
    NSOperationQueue* operationQueue = [[[NSOperationQueue alloc] init] autorelease];
    [operationQueue setMaxConcurrentOperationCount:kZincRepoDefaultNetworkOperationCount];
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
        
        ZINC_DEBUG_LOG(@"[Zincself.repo 0x%x] %@", (int)blockself, error);
        
        ZincErrorEvent* errorEvent = [[[ZincErrorEvent alloc] initWithError:error source:blockself] autorelease];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZincEventNotification object:errorEvent];
        
        [blockself.delegate zincRepo:blockself didEncounterError:error];
    }];
}

- (void) addOperation:(NSOperation*)operation
{
   if ([operation isKindOfClass:[ZincAtomicFileWriteOperation class]]) {
        [self.fileWriteQueue addOperation:operation];
        
    } else if ([operation isKindOfClass:[AFURLConnectionOperation class]]) {
        [self.networkQueue addOperation:operation];
        
    } else if ([operation isKindOfClass:[ZincBundleUpdateTask class]]) {
        [self.bundleUpdateQueue addOperation:operation];
        
    } else {
        [self.defaultQueue addOperation:operation];
    }
}

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
    for (NSURL* sourceURL in self.sourceURLs) {
        ZincSource* source = [ZincSource sourceWithURL:sourceURL];
        ZincCatalogUpdateTask* catalogOp = [[[ZincCatalogUpdateTask alloc] initWithRepo:self source:source] autorelease];
        [self getOrAddTask:catalogOp];
    }
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
    for (NSString* bundleId in [self.trackedBundles allKeys]) {
        NSString* label = [self.trackedBundles objectForKey:bundleId];
        ZincVersion version = [self versionForBundleIdentifier:bundleId label:label];
        if (version != ZincVersionInvalid) {
            
            ZincBundleUpdateTask* bundleOp = [[[ZincBundleUpdateTask alloc]
                                                    initWithRepo:self bundleIdentifier:bundleId version:version]
                                                   autorelease];
            [self getOrAddTask:bundleOp];
        }
    }
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

- (ZincTask*) taskForKey:(NSString*)key
{
    @synchronized(self.myTasks) {
        for (ZincTask* task in self.myTasks) {
            if ([[task key] isEqualToString:key]) {
                return task;
            }
        }
    }
    return nil;
}

- (ZincTask*) getOrAddTask:(ZincTask*)task
{
    @synchronized(self.myTasks) {
        ZincTask* existingTask = [self taskForKey:[task key]];
        
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

-  (void) removeTask:(ZincTask*)task
{
    @synchronized(self.myTasks) {
        ZincTask* foundTask = [self taskForKey:[task key]];
        if (foundTask != nil) {
            [foundTask removeObserver:self forKeyPath:@"isFinished"];
            [self.myTasks removeObject:foundTask];
        }
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &kvo_taskIsFinished) {
        ZincTask* task = (ZincTask*)object;
        if (task.isFinished) {
            [self removeTask:task];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end



