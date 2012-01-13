//
//  ZCBundleManager.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincRepoIndex.h"
#import "ZincBundle.h"
#import "ZincBundle+Private.h"
#import "ZincManifest.h"
#import "ZincSource.h"
#import "ZincCatalog.h"
#import "ZincEvent.h"
#import "ZincResource.h"
#import "ZincBundleCloneTask.h"
#import "ZincBundleDeleteTask.h"
#import "ZincSourceUpdateTask.h"
#import "ZincCatalogUpdateTask.h"
#import "ZincFileDownloadTask.h"
#import "ZincGarbageCollectTask.h"
#import "ZincRepoIndexUpdateTask.h"
#import "ZincOperationQueueGroup.h"
#import "NSFileManager+Zinc.h"
#import "NSData+Zinc.h"
#import "KSJSON.h"
#import "AFNetworking.h"
#import "MAWeakDictionary.h"

#define CATALOGS_DIR @"catalogs"
#define MANIFESTS_DIR @"manifests"
#define FILES_DIR @"files"
#define BUNDLES_DIR @"bundles"
#define DOWNLOADS_DIR @"zinc/downloads"
#define REPO_INDEX_FILE @"repo.json"

static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";

@interface ZincRepo ()

@property (nonatomic, retain) NSURL* url;

// saved state


// runtime state
@property (nonatomic, retain) NSMutableDictionary* sourcesByCatalog;
@property (nonatomic, retain) NSOperationQueue* networkQueue;
@property (nonatomic, retain) ZincOperationQueueGroup* queueGroup;
@property (nonatomic, retain) NSTimer* refreshTimer;
@property (nonatomic, retain) MAWeakDictionary* loadedBundles;
@property (nonatomic, retain) NSCache* cache;
@property (nonatomic, retain) NSMutableArray* myTasks;
@property (nonatomic, retain) NSFileManager* fileManager;

- (void) startRefreshTimer;
- (void) stopRefreshTimer;

- (BOOL) createDirectoriesIfNeeded:(NSError**)outError;
- (NSString*) catalogsPath;
- (NSString*) manifestsPath;
- (NSString*) filesPath;
- (NSString*) bundlesPath;
- (NSString*) downloadsPath;

- (void) queueUpdateIndex;

- (NSString*) cacheKeyForCatalogId:(NSString*)identifier;
- (NSString*) cacheKeyManifestWithBundleId:(NSString*)identifier version:(ZincVersion)version;
- (NSString*) cacheKeyForBundleId:(NSString*)identifier version:(ZincVersion)version;

- (void) registerSource:(ZincSource*)source forCatalog:(ZincCatalog*)catalog;
- (NSArray*) sourcesForCatalogId:(NSString*)catalogId;

- (ZincCatalog*) catalogWithIdentifier:(NSString*)source error:(NSError**)outError;

- (BOOL) isBundleAvailable:(NSString*)bundleId version:(ZincVersion)version;
- (ZincVersion) versionForBundleId:(NSString*)bundleId distribution:(NSString*)distro;
- (void) checkForBundleDeletion;
- (void) deleteBundleWithId:(NSString*)bundleId version:(ZincVersion)version;

- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
- (ZincManifest*) manifestWithBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError;

@end

@implementation ZincRepo

@synthesize delegate = _delegate;
@synthesize index = _index;
@synthesize url = _url;
@synthesize networkQueue = _networkQueue;
@synthesize sourcesByCatalog = _sourcesByCatalog;
@synthesize fileManager = _fileManager;
@synthesize cache = _cache;
@synthesize refreshInterval = _refreshInterval;
@synthesize refreshTimer = _refreshTimer;
@synthesize loadedBundles = _loadedBundles;
@synthesize myTasks = _myTasks;
@synthesize queueGroup = _queueGroup;

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL error:(NSError**)outError
{
    
    NSOperationQueue* operationQueue = [[[NSOperationQueue alloc] init] autorelease];
    [operationQueue setMaxConcurrentOperationCount:kZincRepoDefaultNetworkOperationCount];
    return [self repoWithURL:fileURL networkOperationQueue:operationQueue error:outError];
}

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue error:(NSError**)outError
{
    if ([[[fileURL path] lastPathComponent] isEqualToString:REPO_INDEX_FILE]) {
        fileURL = [NSURL fileURLWithPath:[[fileURL path] stringByDeletingLastPathComponent]];
    }
    
    ZincRepo* repo = [[[ZincRepo alloc] initWithURL:fileURL networkOperationQueue:networkQueue] autorelease];
    if (![repo createDirectoriesIfNeeded:outError]) {
        return nil;
    }
    
    NSString* indexPath = [[fileURL path] stringByAppendingPathComponent:REPO_INDEX_FILE];
    if ([repo.fileManager fileExistsAtPath:indexPath]) {
        
        NSString* jsonString = [[[NSString alloc] initWithContentsOfFile:indexPath encoding:NSUTF8StringEncoding error:outError]
                                autorelease];
        if (jsonString == nil) {
            return nil;
        }
        
        NSDictionary* jsonDict = [KSJSON deserializeString:jsonString error:outError];
        if (jsonDict == nil) {
            return nil;
        }
            
        ZincRepoIndex* index = [[[ZincRepoIndex alloc] initWithDictionary:jsonDict] autorelease];
        repo.index = index;
    }
    return repo;
}

- (id) initWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue
{
    self = [super init];
    if (self) {
        self.url = fileURL;
        self.index = [[[ZincRepoIndex alloc] init] autorelease];
        self.networkQueue = networkQueue;
        self.queueGroup = [[[ZincOperationQueueGroup alloc] init] autorelease];
        [self.queueGroup setMaxConcurrentOperationCount:2 forClass:[ZincBundleCloneTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincCatalogUpdateTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:10 forClass:[ZincFileDownloadTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:2 forClass:[ZincSourceUpdateTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincBundleDeleteTask class]];
        self.fileManager = [[[NSFileManager alloc] init] autorelease];
        self.cache = [[[NSCache alloc] init] autorelease];
        self.cache.countLimit = kZincRepoDefaultCacheCount;
        self.refreshInterval = kZincRepoDefaultAutoRefreshInterval;
        self.sourcesByCatalog = [NSMutableDictionary dictionary];
        self.loadedBundles = [[[MAWeakDictionary alloc] init] autorelease];
        self.myTasks = [NSMutableArray array];
        [self startRefreshTimer];
    }
    return self;
}

- (void) startRefreshTimer
{
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval
                                                         target:self
                                                       selector:@selector(refreshTimerFired:)
                                                       userInfo:nil
                                                        repeats:YES];
    [self.refreshTimer fire];
}

- (void) stopRefreshTimer
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void) checkForBundleDeletion
{
    NSSet* available = [self.index availableBundles];
    NSSet* active = [self activeBundles];

    for (NSURL* bundleRes in available) {
        if (![active containsObject:bundleRes]) {
            ZINC_DEBUG_LOG(@"deleting: %@", bundleRes);
            [self deleteBundleWithId:[bundleRes zincBundleId] version:[bundleRes zincBundleVersion]];
        }
    }
}

- (void) refreshTimerFired:(NSTimer*)timer
{
    __block typeof(self) blockself = self;
    
    [blockself refreshSourcesWithCompletion:^{
        
        [blockself refreshBundlesWithCompletion:^{
            
            ZINC_DEBUG_LOG(@"tick");
            
        }];
        
        [self checkForBundleDeletion];
    }];
    
    //    ZincGarbageCollectTask* gc = [[[ZincGarbageCollectTask alloc] initWithRepo:self] autorelease];
    //    [self getOrAddTask:gc];
    
}

- (void)dealloc
{
    self.url = nil;
    self.index = nil;
    // TODO: stop operations?
    self.networkQueue = nil;
    self.queueGroup = nil;
    self.sourcesByCatalog = nil;
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
    if (![self.fileManager zinc_createDirectoryIfNeededAtPath:[self downloadsPath] error:outError]) {
        return NO;
    }
    return YES;
}

#pragma mark Path Helpers

- (NSURL*) indexURL
{
    return [NSURL fileURLWithPath:[[self.url path] stringByAppendingPathComponent:REPO_INDEX_FILE]];
}

- (NSString*) catalogsPath
{
    return [[self.url path] stringByAppendingPathComponent:CATALOGS_DIR];
}

- (NSString*) manifestsPath
{
    return [[self.url path] stringByAppendingPathComponent:MANIFESTS_DIR];
}

- (NSString*) filesPath
{
    return [[self.url path] stringByAppendingPathComponent:FILES_DIR];
}

- (NSString*) bundlesPath
{
    return [[self.url path] stringByAppendingPathComponent:BUNDLES_DIR];
}

- (NSString*) downloadsPath
{
    return [ZincGetApplicationCacheDirectory() stringByAppendingPathComponent:DOWNLOADS_DIR];
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

- (NSString*) pathForManifestWithBundleId:(NSString*)identifier version:(ZincVersion)version
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
    if ([operation isKindOfClass:[AFURLConnectionOperation class]]) {
        [self.networkQueue addOperation:operation];
    
    } else {
        [self.queueGroup addOperation:operation];
    }
}

#pragma mark Sources

- (void) addSourceURL:(NSURL*)source
{
    [self.index addSourceURL:source];
    [self queueUpdateIndex];
}

- (void) removeSourceURL:(NSURL*)source
{
    @synchronized(self.sourcesByCatalog) {
        for (NSString* catalogId in [self.sourcesByCatalog allKeys]) {
            NSMutableArray* sources = [self.sourcesByCatalog objectForKey:catalogId];
            [sources removeObject:source];
        }
    }
    
    [self.index removeSourceURL:source];
    [self queueUpdateIndex];
}

- (void) registerSource:(NSURL*)source forCatalog:(ZincCatalog*)catalog
{
    @synchronized(self) {
        NSMutableArray* sources = [self.sourcesByCatalog objectForKey:catalog.identifier];
        if (sources == nil) {
            sources = [NSMutableArray array];
            [self.sourcesByCatalog setObject:sources forKey:catalog.identifier];
        }
        // TODO: cleaner duplicate check
        for (ZincSource* existingSource in sources) {
            if ([existingSource isEqual:source]) {
                return;
            }
        }
        [sources addObject:source];
        [self.cache setObject:catalog forKey:[self cacheKeyForCatalogId:catalog.identifier]];
    }
}

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion
{
    NSSet* sourceURLs = [self.index sourceURLS];
    
    NSOperation* parentOp = nil;
    if (completion != nil) {
        parentOp = [[[NSOperation alloc] init] autorelease];
        parentOp.completionBlock = completion;
    }
    
    for (NSURL* source in sourceURLs) {
        ZincSourceUpdateTask* catalogTask = [[[ZincSourceUpdateTask alloc] initWithRepo:self source:source] autorelease];
        catalogTask = (ZincSourceUpdateTask*)[self getOrAddTask:catalogTask];
        [parentOp addDependency:catalogTask];
    }
    
    if (completion != nil) {
        [self addOperation:parentOp];
    }
}

- (NSArray*) sourcesForCatalogId:(NSString*)catalogId
{
    return [self.sourcesByCatalog objectForKey:catalogId];
}

#pragma mark Caching

- (NSString*) cacheKeyForCatalogId:(NSString*)identifier
{
    return [@"Catalog:" stringByAppendingString:identifier];
}

- (NSString*) cacheKeyManifestWithBundleId:(NSString*)identifier version:(ZincVersion)version
{
    return [[@"Manifest:" stringByAppendingString:identifier] stringByAppendingFormat:@"-%d", version];
}

- (NSString*) cacheKeyForBundleId:(NSString*)identifier version:(ZincVersion)version
{
    return [[@"Bundle:" stringByAppendingString:identifier] stringByAppendingFormat:@"-%d", version];
}

#pragma mark Repo Index

- (void) queueUpdateIndex
{
    ZincRepoIndexUpdateTask* task = [[[ZincRepoIndexUpdateTask alloc] initWithRepo:self] autorelease];
    [self getOrAddTask:task];
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
    NSString* key = [self cacheKeyForCatalogId:identifier];
    ZincCatalog* catalog = [self.cache objectForKey:key];
    if (catalog == nil) {
        catalog = [self loadCatalogWithIdentifier:identifier error:outError];
        if (catalog != nil) {
            [self.cache setObject:catalog forKey:key];
        }
    }
    return catalog;
}

#pragma mark Bundles

- (void) addManifest:(ZincManifest*)manifest forBundleId:(NSString*)bundleId
{
    NSString* cacheKey = [self cacheKeyManifestWithBundleId:bundleId version:manifest.version];
    [self.cache setObject:manifest forKey:cacheKey];
}

- (BOOL) removeManifestForBundleId:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError
{
    NSString* manifestPath = [self pathForManifestWithBundleId:bundleId version:version];
    if ([self.fileManager fileExistsAtPath:manifestPath]) {
        if (![self.fileManager removeItemAtPath:manifestPath error:outError]) {
            return NO;
        }
    }
    [self.cache removeObjectForKey:[self cacheKeyManifestWithBundleId:bundleId version:version]];
    return YES;
}

- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version
{
    NSString* path = [self pathForManifestWithBundleId:bundleId version:version];
    return [self.fileManager fileExistsAtPath:path];
}

- (ZincManifest*) loadManifestWithBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError
{
    NSString* manifestPath = [self pathForManifestWithBundleId:bundleId version:version];
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
    NSString* key = [self cacheKeyManifestWithBundleId:bundleId version:version];
    ZincManifest* manifest = [self.cache objectForKey:key];
    if (manifest == nil) {
        manifest = [self loadManifestWithBundleIdentifier:bundleId version:version error:outError];
        if (manifest != nil) {
            [self.cache setObject:manifest forKey:key];
        }
    }
    return [[manifest retain] autorelease];
}

- (NSSet*) activeBundles
{
    NSMutableSet* activeBundles = [NSMutableSet set];
    
    NSSet* trackBundles = [self.index trackedBundleIds];
    for (NSString* bundleId in trackBundles) {
        NSString* dist = [self.index trackedDistributionForBundleId:bundleId];
        ZincVersion version = [self versionForBundleId:bundleId distribution:dist];
        [activeBundles addObject:[NSURL zincResourceForBundleWithId:bundleId version:version]];
    }
    
    @synchronized(self.loadedBundles) {
        for (NSURL* bundleRes in [self.loadedBundles allKeys]) {
            // make sure to request the object, and check if the ref is now nil
            ZincBundle* bundle = [self.loadedBundles objectForKey:bundleRes];
            if (bundle != nil) {
                [activeBundles addObject:bundleRes];
            }
        }
    }
    
    return activeBundles;
}

- (ZincVersion) versionForBundleId:(NSString*)bundleId distribution:(NSString*)distro
{
    NSString* catalogId = [ZincBundle catalogIdFromBundleId:bundleId];
    NSString* bundleName = [ZincBundle bundleNameFromBundleId:bundleId];
    ZincCatalog* catalog = [self catalogWithIdentifier:catalogId error:NULL];
    if (catalog == nil) {
        return ZincVersionInvalid;
    }
    return [catalog versionForBundleName:bundleName distribution:distro];
}

- (BOOL) hasManifestForBundleId:(NSString *)bundleId distribution:(NSString*)distro
{
    NSString* catalogId = [ZincBundle catalogIdFromBundleId:bundleId];
    NSString* bundleName = [ZincBundle bundleNameFromBundleId:bundleId];
    ZincCatalog* catalog = [self catalogWithIdentifier:catalogId error:NULL];
    if (catalog == nil) {
        return NO;
    }
    ZincVersion version = [catalog versionForBundleName:bundleName distribution:distro];
    return [self hasManifestForBundleIdentifier:bundleId version:version];
}

- (void) beginTrackingBundleWithId:(NSString*)bundleId distribution:(NSString*)distro
{
    [self.index addTrackedBundleId:bundleId distribution:distro];
    [self queueUpdateIndex];

    ZincVersion version = [self versionForBundleId:bundleId distribution:distro];
    if (![self isBundleAvailable:bundleId version:version]) {
        
        ZincBundleCloneTask* bundleTask = [[[ZincBundleCloneTask alloc]
                                            initWithRepo:self bundleId:bundleId version:version]
                                           autorelease];
        [self getOrAddTask:bundleTask];
    }
}

- (void) stopTrackingBundleWithId:(NSString*)bundleId
{
    [self.index removeTrackedBundleId:bundleId];
    [self queueUpdateIndex];  
}

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion
{
    NSOperation* parentOp = nil;
    if (completion != nil) {
        parentOp = [[[NSOperation alloc] init] autorelease];
        parentOp.completionBlock = completion;
    }
    
    NSSet* trackBundles = [self.index trackedBundleIds];
    
    for (NSString* bundleId in trackBundles) {
        
        NSString* distro = [self.index trackedDistributionForBundleId:bundleId];
        ZincVersion version = [self versionForBundleId:bundleId distribution:distro];
        if (version == ZincVersionInvalid) {
            continue;
        };
        
        if ([self isBundleAvailable:bundleId version:version]) {
            // already downloaded
            continue;
        }
        
        ZincBundleCloneTask* bundleTask = [[[ZincBundleCloneTask alloc]
                                            initWithRepo:self bundleId:bundleId version:version]
                                           autorelease];
        bundleTask = (ZincBundleCloneTask*)[self getOrAddTask:bundleTask];
        [parentOp addDependency:bundleTask];
    }
    
    if (completion != nil) {
        [self addOperation:parentOp];
    }
}

- (void) deleteBundleWithId:(NSString*)bundleId version:(ZincVersion)version
{
    ZincBundleDeleteTask* deleteTask = [[[ZincBundleDeleteTask alloc] initWithRepo:self bundleId:bundleId version:version] autorelease];
    [self getOrAddTask:deleteTask];  
}

// TODO: make sure it's not active!!

#pragma mark Bundles

- (BOOL) isBundleAvailable:(NSString*)bundleId version:(ZincVersion)version
{
    NSSet* available = [self.index availableBundles];
    for (NSURL* bundleRes in available) {
        if ([[bundleRes zincBundleId] isEqualToString:bundleId] &&
            [bundleRes zincBundleVersion] == version) {
            return YES;
        }
    }
    return NO;
}

- (void) registerBundle:(NSURL*)bundleResource
{
    [self.index addAvailableBundle:bundleResource];
    [self queueUpdateIndex];
}

- (void) deregisterBundle:(NSURL*)bundleResource
{
    [self.index removeAvailableBundle:bundleResource];
    [self queueUpdateIndex];
}

- (NSString*) pathForBundleWithId:(NSString*)bundleId version:(ZincVersion)version
{
    NSString* bundleDirName = [NSString stringWithFormat:@"%@-%d", bundleId, version];
    NSString* bundlePath = [[self bundlesPath] stringByAppendingPathComponent:bundleDirName];
    return bundlePath;
}

- (ZincBundle*) bundleWithId:(NSString*)bundleId version:(ZincVersion)version
{
    ZincBundle* bundle = nil;
    
    @synchronized(self.loadedBundles) {
        bundle = [self.loadedBundles objectForKey:bundleId];
        
        if (bundle == nil) {
            
            NSString* path = [self pathForBundleWithId:bundleId version:version];
            bundle = [[[ZincBundle alloc] initWithBundleId:bundleId version:version bundleURL:[NSURL fileURLWithPath:path]] autorelease];
            if (bundle == nil) return nil;
            
            // TODO: handle error
            
            NSURL* res = [NSURL zincResourceForBundleWithId:bundleId version:version];
            [self.loadedBundles setObject:bundle forKey:res];
        }
    }
    return bundle;
}

- (ZincBundle*) bundleWithId:(NSString*)bundleId
{
    NSString* distro = [self.index trackedDistributionForBundleId:bundleId];
    ZincVersion version = [self versionForBundleId:bundleId distribution:distro];
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

- (void) suspendAllTasks
{
    [self stopRefreshTimer];
    [self.queueGroup setSuspended:YES];
}

- (void) resumeAllTasks
{
    [self.queueGroup setSuspended:NO];
    [self startRefreshTimer];
}

- (ZincTask*) taskForDescriptor:(ZincTaskDescriptor*)taskDescriptor
{
    @synchronized(self.myTasks) {
        for (ZincTask* task in self.myTasks) {
            if ([[task taskDescriptor] isEqual:taskDescriptor]) {
                return task;
            }
        }
    }
    return nil;
}

- (NSArray*) tasksForResource:(NSURL*)resource
{
    @synchronized(self.myTasks) {
        NSMutableArray* tasks = [NSMutableArray array];
        for (ZincTask* task in self.myTasks) {
            if ([task.resource isEqual:resource]) {
                [tasks addObject:task];
            }
        }
        return tasks;
    }
}

- (ZincTask*) getOrAddTask:(ZincTask*)task
{
    @synchronized(self.myTasks) {
        
        NSArray* tasksMatchingResource = [self tasksForResource:task.resource];
        
        // look for an exact match
        ZincTask* existingTask = nil;
        for (ZincTask* resourceTask in tasksMatchingResource) {
            if ([[resourceTask taskDescriptor] isEqual:[task taskDescriptor]]) {
                existingTask = resourceTask;
            }
        }
        
        // if no exact match found, add task and depends for all other resource-matching
        if (existingTask == nil) {
            
            for (ZincTask* resourceTask in tasksMatchingResource) {
                if (resourceTask != existingTask) {
                    [task addDependency:resourceTask];
                }
            }
            
            [self.myTasks addObject:task];
            [task addObserver:self forKeyPath:@"isFinished" options:0 context:&kvo_taskIsFinished];
            [self addOperation:task];
            return task;
            
        } else {
            
            ZINC_DEBUG_LOG(@"[Zincself.repo 0x%x] Task already exists! %@", (int)self, task);
            return existingTask;
        }
    }
}

-  (void) removeTask:(ZincTask*)task
{
    @synchronized(self.myTasks) {
        ZincTask* foundTask = [self taskForDescriptor:[task taskDescriptor]];
        if (foundTask != nil) {
            [foundTask removeObserver:self forKeyPath:@"isFinished"];
            [self.myTasks removeObject:foundTask];
        }
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
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



