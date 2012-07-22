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
#import "ZincEvent+Private.h"
#import "ZincResource.h"
#import "ZincTaskDescriptor.h"
#import "ZincBundleRemoteCloneTask.h"
#import "ZincBundleBootstrapTask.h"
#import "ZincBundleDeleteTask.h"
#import "ZincSourceUpdateTask.h"
#import "ZincCatalogUpdateTask.h"
#import "ZincObjectDownloadTask.h"
#import "ZincGarbageCollectTask.h"
#import "ZincRepoIndexUpdateTask.h"
#import "ZincArchiveExtractOperation.h"
#import "ZincOperationQueueGroup.h"
#import "ZincUtils.h"
#import "NSFileManager+Zinc.h"
#import "NSData+Zinc.h"
#import "ZincKSJSON.h"
#import "ZincHTTPRequestOperation.h"
#import "ZincSerialQueueProxy.h"

#define CATALOGS_DIR @"catalogs"
#define MANIFESTS_DIR @"manifests"
#define FILES_DIR @"objects"
#define BUNDLES_DIR @"bundles"
#define DOWNLOADS_DIR @"zinc/downloads"
#define REPO_INDEX_FILE @"repo.json"

NSString* const ZincRepoBundleChangeNotifiationBundleIdKey = @"bundleId";
NSString* const ZincRepoBundleChangeNotifiationStatusKey = @"status";
NSString* const ZincRepoBundleCloneProgressKey = @"progress";

NSString* const ZincRepoBundleStatusChangeNotification = @"ZincRepoBundleStatusChangeNotification";
NSString* const ZincRepoBundleWillDeleteNotification = @"ZincRepoBundleWillDeleteNotification";
NSString* const ZincRepoBundleDidBeginTrackingNotification = @"ZincRepoBundleDidBeginTrackingNotification";
NSString* const ZincRepoBundleWillStopTrackingNotification = @"ZincRepoBundleWillStopTrackingNotification";
NSString* const ZincRepoBundleCloneProgressNotification = @"ZincRepoBundleCloneProgressNotification";

static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";
static NSString* kvo_taskProgress = @"kvo_taskProgress";

@interface ZincRepo ()

@property (nonatomic, retain) NSURL* url;

// runtime state
@property (nonatomic, retain) NSMutableDictionary* sourcesByCatalog;
@property (nonatomic, retain) NSOperationQueue* networkQueue;
@property (nonatomic, retain) ZincOperationQueueGroup* queueGroup;
@property (nonatomic, retain) NSTimer* refreshTimer;
@property (nonatomic, retain) NSMutableDictionary* loadedBundles;
@property (nonatomic, retain) NSCache* cache;
@property (nonatomic, retain) NSMutableArray* myTasks;
@property (nonatomic, retain) NSFileManager* fileManager;

@property (nonatomic, readonly) ZincSerialQueueProxy* indexProxy;

- (void) startRefreshTimer;
- (void) stopRefreshTimer;

- (BOOL) createDirectoriesIfNeeded:(NSError**)outError;
- (NSString*) catalogsPath;
- (NSString*) manifestsPath;
- (NSString*) filesPath;
- (NSString*) bundlesPath;
- (NSString*) downloadsPath;

- (void) queueIndexSave;
- (ZincTask*) queueGarbageCollectTask;
- (void) resumeBundleActions;

- (NSString*) cacheKeyForCatalogId:(NSString*)identifier;
- (NSString*) cacheKeyManifestWithBundleId:(NSString*)identifier version:(ZincVersion)version;
- (NSString*) cacheKeyForBundleId:(NSString*)identifier version:(ZincVersion)version;

- (void) registerSource:(NSURL*)source forCatalog:(ZincCatalog*)catalog;
- (NSArray*) sourcesForCatalogId:(NSString*)catalogId;

- (ZincCatalog*) catalogWithIdentifier:(NSString*)source error:(NSError**)outError;

- (ZincVersion) versionForBundleId:(NSString*)bundleId distribution:(NSString*)distro;
- (void) checkForBundleDeletion;
- (void) deleteBundleWithId:(NSString*)bundleId version:(ZincVersion)version;

- (BOOL) hasManifestForBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;
- (ZincManifest*) manifestWithBundleId:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError;

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
        
        NSDictionary* jsonDict = [ZincKSJSON deserializeString:jsonString error:outError];
        if (jsonDict == nil) {
            return nil;
        }
        
        ZincRepoIndex* index = [ZincRepoIndex repoIndexFromDictionary:jsonDict error:outError];
        if (index == nil) {
            return nil;
        }
        repo.index = index;
    }
    
    [repo.queueGroup setSuspended:YES];
    
    [repo queueGarbageCollectTask];
    
    return repo;
}

+ (BOOL) repoExistsAtURL:(NSURL*)fileURL
{
    NSString* path = [fileURL path];
    if (![[path lastPathComponent] isEqualToString:REPO_INDEX_FILE]) {
        path = [path stringByAppendingPathComponent:REPO_INDEX_FILE];
    }
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}


- (id) initWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue
{
    self = [super init];
    if (self) {
        self.url = fileURL;
        self.index = [[[ZincRepoIndex alloc] init] autorelease];
        self.networkQueue = networkQueue;
        self.queueGroup = [[[ZincOperationQueueGroup alloc] init] autorelease];
        [self.queueGroup setMaxConcurrentOperationCount:2 forClass:[ZincBundleRemoteCloneTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincBundleBootstrapTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincCatalogUpdateTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:10 forClass:[ZincObjectDownloadTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:2 forClass:[ZincSourceUpdateTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincBundleDeleteTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincArchiveExtractOperation class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincGarbageCollectTask class]];
        self.fileManager = [[[NSFileManager alloc] init] autorelease];
        self.cache = [[[NSCache alloc] init] autorelease];
        self.cache.countLimit = kZincRepoDefaultCacheCount;
        _refreshInterval = kZincRepoDefaultAutoRefreshInterval;
        self.sourcesByCatalog = [NSMutableDictionary dictionary];
        self.loadedBundles = [[[NSMutableDictionary alloc] init] autorelease];
        self.myTasks = [NSMutableArray array];
    }
    return self;
}

- (void) setIndex:(ZincRepoIndex *)index
{
    [_index autorelease];
    
    if (index != nil) {
        ZincSerialQueueProxy* proxy = [[ZincSerialQueueProxy alloc] initWithTarget:index];
        _index = (ZincRepoIndex*)proxy;
    } else {
        _index = nil;
    }
}

- (void) setRefreshInterval:(NSTimeInterval)refreshInterval
{
    _refreshInterval = refreshInterval;
    [self startRefreshTimer];
}

- (ZincSerialQueueProxy*) indexProxy
{
    return (ZincSerialQueueProxy*)self.index;
}

- (void) startRefreshTimer
{
    [self stopRefreshTimer];
    
    if (self.refreshInterval > 0) {
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval
                                                             target:self
                                                           selector:@selector(refreshTimerFired:)
                                                           userInfo:nil
                                                            repeats:YES];
        [self.refreshTimer fire];
    }
}

- (void) stopRefreshTimer
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void) checkForBundleDeletion
{
    [self.indexProxy executeBlock:^{
        
        NSSet* cloningBundles = [self.index cloningBundles];
        if ([cloningBundles count] > 1) {
            // don't delete while any clones are in progress
            return;
        }
        
        NSSet* available = [self.index availableBundles];
        NSSet* active = [self activeBundles];
        
        for (NSURL* bundleRes in available) {
            if (![active containsObject:bundleRes]) {
                //ZINC_DEBUG_LOG(@"deleting: %@", bundleRes);
                [self deleteBundleWithId:[bundleRes zincBundleId] version:[bundleRes zincBundleVersion]];
            }
        }
    }];
}

- (void) refreshTimerFired:(NSTimer*)timer
{
    __block typeof(self) blockself = self;
    
    ZINC_DEBUG_LOG(@"<fire>");
    
    [blockself refreshSourcesWithCompletion:^{
        
        [blockself resumeBundleActions];
        
        [blockself refreshBundlesWithCompletion:^{
            
            [blockself checkForBundleDeletion];
            
            ZINC_DEBUG_LOG(@"</fire>");
            
        }];
    }];
}

- (void)dealloc
{
    [_url release];
    [_index release];
    // TODO: stop operations?
    [_networkQueue release];
    [_queueGroup release];
    [_sourcesByCatalog release];
    [_cache release];
    [_loadedBundles release];
    [_myTasks release];
    [super dealloc];
}

#pragma mark Notifications

- (void) postNotification:(NSString*)notificationName userInfo:(NSDictionary*)userInfo
{
    __block typeof(self) blockself = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                            object:blockself
                                                          userInfo:userInfo];
    }];
}

- (void) postProgressNotificationForBundleId:(NSString*)bundleId progress:(float)progress
{
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              bundleId, ZincRepoBundleChangeNotifiationBundleIdKey,
                              [NSNumber numberWithFloat:progress], ZincRepoBundleCloneProgressKey,
                              nil];
    [self postNotification:ZincRepoBundleCloneProgressNotification userInfo:userInfo];
}

- (void) postNotification:(NSString*)notificationName bundleId:(NSString*)bundleId state:(ZincBundleState)state
{
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              bundleId, ZincRepoBundleChangeNotifiationBundleIdKey,
                              [NSNumber numberWithInteger:state], ZincRepoBundleChangeNotifiationStatusKey,
                              nil];
    [self postNotification:notificationName userInfo:userInfo];
}

- (void) postNotification:(NSString*)notificationName bundleId:(NSString*)bundleId
{
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              bundleId, ZincRepoBundleChangeNotifiationBundleIdKey,
                              nil];
    [self postNotification:notificationName userInfo:userInfo];
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
    return [[self filesPath] stringByAppendingPathComponent:sha];
}

- (BOOL) hasFileWithSHA:(NSString*)sha
{
    return [self.fileManager fileExistsAtPath:[self pathForFileWithSHA:sha]];
}


#pragma mark Internal Operations

- (void) addOperation:(NSOperation*)operation
{
    if ([operation isKindOfClass:[ZincNetworkOperation class]]) {
        [self.networkQueue addOperation:operation];
    } else {
        [self.queueGroup addOperation:operation];
    }
}

#pragma mark Sources

- (void) addSourceURL:(NSURL*)source
{
    [self.index addSourceURL:source];
    [self queueIndexSave];
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
    [self queueIndexSave];
}

- (void) registerSource:(NSURL*)source forCatalog:(ZincCatalog*)catalog
{
    @synchronized(self.sourcesByCatalog) {
        NSMutableArray* sources = [self.sourcesByCatalog objectForKey:catalog.identifier];
        if (sources == nil) {
            sources = [NSMutableArray array];
            [self.sourcesByCatalog setObject:sources forKey:catalog.identifier];
        }
        // TODO: cleaner duplicate check
        for (NSURL* existingSource in sources) {
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
    NSSet* sourceURLs = [self.index sourceURLs];
    
    NSOperation* parentOp = nil;
    if (completion != nil) {
        parentOp = [[[NSOperation alloc] init] autorelease];
        parentOp.completionBlock = completion;
    }
    
    for (NSURL* source in sourceURLs) {
        ZincTaskDescriptor* taskDesc = [ZincSourceUpdateTask taskDescriptorForResource:source];
        ZincTask* task = (ZincSourceUpdateTask*)[self queueTaskForDescriptor:taskDesc];
        [parentOp addDependency:task];
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

- (void) queueIndexSave
{
    ZincTaskDescriptor* taskDesc = [ZincRepoIndexUpdateTask taskDescriptorForResource:[self indexURL]];
    [self queueTaskForDescriptor:taskDesc];
}

#pragma mark Catalogs

- (void) registerCatalog:(ZincCatalog*)catalog
{
    NSString* key = [self cacheKeyForCatalogId:catalog.identifier];
    [self.cache setObject:catalog forKey:key];
}

- (ZincCatalog*) loadCatalogWithIdentifier:(NSString*)identifier error:(NSError**)outError
{
    NSString* catalogPath = [[[self catalogsPath] stringByAppendingPathComponent:identifier] stringByAppendingPathExtension:@"json"];
    NSString* jsonString = [NSString stringWithContentsOfFile:catalogPath encoding:NSUTF8StringEncoding error:outError];
    if (jsonString == nil) {
        return nil;
    }
    NSDictionary* jsonDict = [ZincKSJSON deserializeString:jsonString error:outError];
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

- (ZincManifest*) importManifestWithPath:(NSString*)manifestPath error:(NSError**)outError
{
    // read manifest
    NSString* jsonString = [NSString stringWithContentsOfFile:manifestPath encoding:NSUTF8StringEncoding error:outError];
    if (jsonString == nil) {
        return nil;
    }
    
    // copy manifest to repo
    NSDictionary* manifestDict = [ZincKSJSON deserializeString:jsonString error:outError];
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:manifestDict] autorelease];
    NSString* manifestRepoPath = [self pathForManifestWithBundleId:manifest.bundleName version:manifest.version];
    if (![self.fileManager fileExistsAtPath:manifestRepoPath]) {
        if (![self.fileManager copyItemAtPath:manifestPath toPath:manifestRepoPath error:outError]) {
            return nil;
        }
    }
    
    return manifest;
}

- (ZincManifest*) loadManifestWithBundleId:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError
{
    NSString* manifestPath = [self pathForManifestWithBundleId:bundleId version:version];
    NSString* jsonString = [NSString stringWithContentsOfFile:manifestPath encoding:NSUTF8StringEncoding error:outError];
    if (jsonString == nil) {
        return nil;
    }
    NSDictionary* jsonDict = [ZincKSJSON deserializeString:jsonString error:outError];
    if (jsonDict == nil) {
        return nil;
    }
    ZincManifest* manifest = [[[ZincManifest alloc] initWithDictionary:jsonDict] autorelease];
    return manifest;
}

- (ZincManifest*) manifestWithBundleId:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError
{
    NSString* key = [self cacheKeyManifestWithBundleId:bundleId version:version];
    ZincManifest* manifest = [self.cache objectForKey:key];
    if (manifest == nil) {
        manifest = [self loadManifestWithBundleId:bundleId version:version error:outError];
        if (manifest != nil) {
            [self.cache setObject:manifest forKey:key];
        }
    }
    return [[manifest retain] autorelease];
}

- (NSSet*) activeBundles
{
    NSMutableSet* activeBundles = [NSMutableSet set];
    
    [self.indexProxy executeBlock:^{
        NSSet* trackBundles = [self.index trackedBundleIds];
        for (NSString* bundleId in trackBundles) {
            NSString* dist = [self.index trackedDistributionForBundleId:bundleId];
            ZincVersion version = [self versionForBundleId:bundleId distribution:dist];
            [activeBundles addObject:[NSURL zincResourceForBundleWithId:bundleId version:version]];
        }
    }];
    
    @synchronized(self.loadedBundles) {
        for (NSURL* bundleRes in [self.loadedBundles allKeys]) {
            // make sure to request the object, and check if the ref is now nil
            ZincBundle* bundle = [[self.loadedBundles objectForKey:bundleRes] pointerValue];
            if (bundle != nil) {
                [activeBundles addObject:bundleRes];
            }
        }
    }
    
    return activeBundles;
}

- (void) bundleWillDeallocate:(ZincBundle*)bundle
{
    @synchronized(self.loadedBundles) {
        [self.loadedBundles removeObjectForKey:[bundle resource]];
    }
}

- (ZincVersion) catalogVersionForBundleId:(NSString*)bundleId distribution:(NSString*)distro
{
    NSError* error = nil;
    
    NSString* catalogId = [ZincBundle catalogIdFromBundleId:bundleId];
    ZincCatalog* catalog = [self catalogWithIdentifier:catalogId error:&error];
    if (catalog != nil) {
        NSString* bundleName = [ZincBundle bundleNameFromBundleId:bundleId];
        ZincVersion catalogVersion = [catalog versionForBundleId:bundleName distribution:distro];
        return catalogVersion;
    }

    return ZincVersionInvalid;
}

- (ZincVersion) versionForBundleId:(NSString*)bundleId distribution:(NSString*)distro
{
    NSArray* availableVersions = [self.index availableVersionsForBundleId:bundleId];
    
    if ([availableVersions count] == 0) {
        return ZincVersionInvalid;
    }
    
    ZincVersion catalogVersion = [self catalogVersionForBundleId:bundleId distribution:distro];
    if ([availableVersions containsObject:[NSNumber numberWithInteger:catalogVersion]]) {
        return catalogVersion;
    }
    
    return [[availableVersions lastObject] integerValue];
}

- (BOOL) hasManifestForBundleId:(NSString *)bundleId distribution:(NSString*)distro
{
    NSString* catalogId = [ZincBundle catalogIdFromBundleId:bundleId];
    NSString* bundleName = [ZincBundle bundleNameFromBundleId:bundleId];
    ZincCatalog* catalog = [self catalogWithIdentifier:catalogId error:NULL];
    if (catalog == nil) {
        return NO;
    }
    ZincVersion version = [catalog versionForBundleId:bundleName distribution:distro];
    return [self hasManifestForBundleIdentifier:bundleId version:version];
}

- (BOOL) bootstrapBundleWithId:(NSString*)bundleId manifestPath:(NSString*)manifesPath waitUntilDone:(BOOL)wait
{
    NSParameterAssert(bundleId);
    NSParameterAssert(manifesPath);
 
    NSError* error = nil;
    ZincManifest* localManifest = [ZincManifest manifestWithPath:manifesPath error:&error];
    if (localManifest == nil) {
        [self logEvent:[ZincErrorEvent eventWithError:error source:self]];
        return NO;
    }  
    
    __block ZincTask* bootstrapTask = nil;
    
    [self.indexProxy executeBlock:^{
        
        NSInteger newestVersion = [self.index newestAvailableVersionForBundleId:bundleId];
        if (newestVersion <= 0 || localManifest.version > newestVersion) {
            // must always bootstrap v0
            
            NSString* currentDistro = [self.index trackedDistributionForBundleId:bundleId];
            if (currentDistro == nil) {
                [self.index addTrackedBundleId:bundleId distribution:ZincDistributionLocal];
            }

            NSURL* localBundleRes = [localManifest bundleResource];
            [self.index setState:ZincBundleStateCloning forBundle:localBundleRes];
            ZincTaskDescriptor* taskDesc = [ZincBundleBootstrapTask taskDescriptorForResource:localBundleRes];
            
            NSDictionary* inputDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                       manifesPath, @"manifestPath", nil];
            bootstrapTask = [self queueTaskForDescriptor:taskDesc input:inputDict];
        }
        
        [self queueIndexSave];
    }];
    
    if (wait) {
        if (self.isSuspended) {
            NSLog(@"WARNING: repo is suspended. This will likely wait forever");
        }
        [bootstrapTask waitUntilFinished];
    };
    
    return YES;
}

- (BOOL) bootstrapBundleWithId:(NSString*)bundleId fromDir:(NSString*)dir waitUntilDone:(BOOL)wait
{
    NSParameterAssert(bundleId);
    NSParameterAssert(dir);
    
    NSString* potentialManifestPath = [dir stringByAppendingPathComponent:
                                       [bundleId stringByAppendingPathExtension:@"json"]];
    if ([self.fileManager fileExistsAtPath:potentialManifestPath]) {
        
        return [self bootstrapBundleWithId:bundleId manifestPath:potentialManifestPath  waitUntilDone:wait];
    }

    return NO;
}

- (void) beginTrackingBundleWithId:(NSString *)bundleId distribution:(NSString *)distro
{
    [self.indexProxy executeBlock:^{
        
        [self.index addTrackedBundleId:bundleId distribution:distro];
        
        ZincVersion catalogVersion = [self catalogVersionForBundleId:bundleId distribution:distro];
        if (catalogVersion != ZincVersionInvalid) { // found in a remote catalog
            
            NSURL* catalogBundleRes = [NSURL zincResourceForBundleWithId:bundleId version:catalogVersion];
            
            ZincBundleState state = [self.index stateForBundle:catalogBundleRes];
            if (state != ZincBundleStateCloning && state != ZincBundleStateAvailable) {
                [self.index setState:ZincBundleStateCloning forBundle:catalogBundleRes];
                ZincTaskDescriptor* taskDesc = [ZincBundleRemoteCloneTask taskDescriptorForResource:catalogBundleRes];
                [self queueTaskForDescriptor:taskDesc];
            }
        }
        
        [self queueIndexSave];
    }];
    
    [self postNotification:ZincRepoBundleDidBeginTrackingNotification bundleId:bundleId];
}

- (void) stopTrackingBundleWithId:(NSString*)bundleId
{
    [self postNotification:ZincRepoBundleWillStopTrackingNotification bundleId:bundleId];
    
    [self.index removeTrackedBundleId:bundleId];
    [self queueIndexSave];  
}

- (NSSet*) trackedBundleIds
{
    return [self.index trackedBundleIds];
}

- (void) resumeBundleActions
{
    [self.indexProxy executeBlock:^{
        for (NSURL* bundleRes in [self.index cloningBundles]) {
            if ([bundleRes zincBundleVersion] > 0) {
                [self queueTaskForDescriptor:[ZincBundleRemoteCloneTask taskDescriptorForResource:bundleRes]];
            }
        }
    }];
}

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion
{
    NSOperation* parentOp = nil;
    if (completion != nil) {
        parentOp = [[[NSOperation alloc] init] autorelease];
        parentOp.completionBlock = completion;
    }
    
    [self.indexProxy executeBlock:^{
        
        NSSet* trackBundles = [self.index trackedBundleIds];
        
        for (NSString* bundleId in trackBundles) {
            
            NSString* distro = [self.index trackedDistributionForBundleId:bundleId];
            ZincVersion version = [self catalogVersionForBundleId:bundleId distribution:distro];
            if (version == ZincVersionInvalid) {
                continue;
            };
            
            NSURL* bundleRes = [NSURL zincResourceForBundleWithId:bundleId version:version];
            ZincBundleState state = [self.index stateForBundle:bundleRes];
            
            if (state == ZincBundleStateCloning || state == ZincBundleStateAvailable) {
                // already downloading/downloaded
                continue;
            }
            
            [self.index setState:ZincBundleStateCloning forBundle:bundleRes];
            
            ZincTaskDescriptor* taskDesc = [ZincBundleRemoteCloneTask taskDescriptorForResource:bundleRes];
            ZincTask* bundleTask = [self queueTaskForDescriptor:taskDesc];
            [parentOp addDependency:bundleTask];
        }
    }];
    
    
    if (completion != nil) {
        [self addOperation:parentOp];
    }
}

- (void) deleteBundleWithId:(NSString*)bundleId version:(ZincVersion)version
{
    NSURL* bundleRes = [NSURL zincResourceForBundleWithId:bundleId version:version];
    ZincTaskDescriptor* taskDesc = [ZincBundleDeleteTask taskDescriptorForResource:bundleRes];
    [self queueTaskForDescriptor:taskDesc];
}

#pragma mark Bundles

- (void) registerBundle:(NSURL*)bundleResource status:(ZincBundleState)status
{
    [self.index setState:status forBundle:bundleResource];
    [self postNotification:ZincRepoBundleStatusChangeNotification bundleId:[bundleResource zincBundleId] state:status];
    [self queueIndexSave];
}

- (void) deregisterBundle:(NSURL*)bundleResource
{
    [self postNotification:ZincRepoBundleWillDeleteNotification bundleId:[bundleResource zincBundleId]];
    [self.index removeBundle:bundleResource];
    [self queueIndexSave];
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
    NSURL* res = [NSURL zincResourceForBundleWithId:bundleId version:version];
    
    @synchronized(self.loadedBundles) {
        bundle = [[self.loadedBundles objectForKey:res] pointerValue];
        
        if (bundle == nil) {
            
            NSString* path = [self pathForBundleWithId:bundleId version:version];
            bundle = [[[ZincBundle alloc] initWithRepo:self bundleId:bundleId version:version bundleURL:[NSURL fileURLWithPath:path]] autorelease];
            if (bundle == nil) return nil;
            
            [self.loadedBundles setObject:[NSValue valueWithPointer:bundle] forKey:res];
        }
    }
    return [[bundle retain] autorelease];
}

- (ZincBundleState) stateForBundleWithId:(NSString*)bundleId 
{
    __block ZincBundleState state;
    [self.indexProxy executeBlock:^{
        NSString* distro = [self.index trackedDistributionForBundleId:bundleId];
        ZincVersion version = [self versionForBundleId:bundleId distribution:distro];
        NSURL* bundleRes = [NSURL zincResourceForBundleWithId:bundleId version:version];
        state = [self.index stateForBundle:bundleRes];
    }];
    return state;
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

- (BOOL) isSuspended
{
    return self.refreshTimer == nil;
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

- (NSArray*) tasksWithMethod:(NSString*)method
{
    @synchronized(self.myTasks) {
        return [self.myTasks filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"method = %@", method]];
    }
}


- (void) queueTask:(ZincTask*)task
{
    @synchronized(self.myTasks) {
        [self.myTasks addObject:task];
        [task addObserver:self forKeyPath:@"isFinished" options:0 context:&kvo_taskIsFinished];
        [task addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:&kvo_taskProgress];
        [self addOperation:task];
    }
}

- (ZincTask*) queueGarbageCollectTask
{
    ZincTask* task = nil;
    
    BOOL hasExistingGarbageCollectTasks = 
    [[[self.queueGroup getQueueForClass:[ZincGarbageCollectTask class]] operations] count] > 0;
    
    if (!hasExistingGarbageCollectTasks) {
        
        task = [[[ZincGarbageCollectTask alloc] initWithRepo:self resourceDescriptor:self.url] autorelease];
        
        for (NSOperation* existingTask in self.myTasks) {
            [task addDependency:existingTask];
        }
        
        [self queueTask:task];
    }
    return task;
}

- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input dependencies:(NSArray*)dependencies
{
    ZincTask* task = nil;
    
    if ([taskDescriptor.method isEqualToString:NSStringFromClass([ZincGarbageCollectTask class])]) {
        
        task = [self queueGarbageCollectTask];
        
    } else {
        
        NSArray* tasksMatchingResource = [self tasksForResource:taskDescriptor.resource];
        
        // look for task that also matches the action
        ZincTask* existingTask = nil;
        for (ZincTask* potentialMatchingTask in tasksMatchingResource) {
            if ([[potentialMatchingTask taskDescriptor].action isEqual:taskDescriptor.action]) {
                existingTask = potentialMatchingTask;
            }
        }
        
        // if no exact match found, add task and depends for all other resource-matching
        if (existingTask == nil) {
            
            task = [ZincTask taskWithDescriptor:taskDescriptor repo:self input:input];
            
            for (ZincTask* resourceTask in tasksMatchingResource) {
                if (resourceTask != task) {
                    [task addDependency:resourceTask];
                }
            }
            
            // !!!: special case for bundle clone tasks
            if ([task isKindOfClass:[ZincBundleCloneTask class]]) {
                NSArray* deleteOps = [[self.queueGroup getQueueForClass:[ZincBundleDeleteTask class]] operations];
                for (NSOperation* deleteOp in deleteOps) {
                    [task addDependency:deleteOp];
                }
            }
            
            // !!!: special case for garbage collect tasks
            NSArray* garbageCollectOps = [[self.queueGroup getQueueForClass:[ZincGarbageCollectTask class]]  operations];
            for (NSOperation* garbageCollectOp in garbageCollectOps) {
                [task addDependency:garbageCollectOp];
            }
            
            [self queueTask:task];
            
        } else {
            
            //ZINC_DEBUG_LOG(@"[Zincself.repo 0x%x] Task already exists! %@", (int)self, taskDescriptor);
            task = existingTask;
        }
        
        // add all explicit dependencies
        for (NSOperation* dep in dependencies) {
            [task addDependency:dep];
        }
    }
    
    return task;
}

- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input
{
    return [self queueTaskForDescriptor:taskDescriptor input:input dependencies:nil];
}

- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor
{
    return [self queueTaskForDescriptor:taskDescriptor input:nil];
}

-  (void) removeTask:(ZincTask*)task
{
    @synchronized(self.myTasks) {
        ZincTask* foundTask = [self taskForDescriptor:[task taskDescriptor]];
        if (foundTask != nil) {
            [foundTask removeObserver:self forKeyPath:@"progress" context:&kvo_taskProgress];
            [foundTask removeObserver:self forKeyPath:@"isFinished" context:&kvo_taskIsFinished];
            [self.myTasks removeObject:foundTask];
        }
    }
}

- (void) logEvent:(ZincEvent*)event
{
    __block typeof(self) blockself = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([blockself.delegate respondsToSelector:@selector(zincRepo:didReceiveEvent:)])
            [blockself.delegate zincRepo:blockself didReceiveEvent:event];
        
        NSMutableDictionary* userInfo = [[event.attributes mutableCopy] autorelease];
        if (event.source != nil) {
            [userInfo setObject:event.source forKey:kZincEventNotificationSourceKey];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:[[event class] notificationName] object:self userInfo:userInfo];        
    }];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kvo_taskIsFinished) {
        ZincTask* task = (ZincTask*)object;
        if (task.isFinished) {
            [self removeTask:task];
        }
    } else if (context == &kvo_taskProgress) {

        ZincTask* task = (ZincTask*)object;
        NSString* bundleId = [task.resource zincBundleId];
        float progress = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        [self postProgressNotificationForBundleId:bundleId progress:progress];
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end



