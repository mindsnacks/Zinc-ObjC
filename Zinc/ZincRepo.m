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
#import "ZincBundleCloneTask.h"
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

NSString* const ZincRepoBundleStatusChangeNotification = @"ZincRepoBundleStatusChangeNotification";
NSString* const ZincRepoBundleWillDeleteNotification = @"ZincRepoBundleWillDeleteNotification";
NSString* const ZincRepoBundleDidBeginTrackingNotification = @"ZincRepoBundleDidBeginTrackingNotification";
NSString* const ZincRepoBundleWillStopTrackingNotification = @"ZincRepoBundleWillStopTrackingNotification";

static NSString* kvo_taskIsFinished = @"kvo_taskIsFinished";

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
    
    [repo startRefreshTimer];
    
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
        [self.queueGroup setMaxConcurrentOperationCount:2 forClass:[ZincBundleCloneTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincCatalogUpdateTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:10 forClass:[ZincObjectDownloadTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:2 forClass:[ZincSourceUpdateTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincBundleDeleteTask class]];
        [self.queueGroup setMaxConcurrentOperationCount:1 forClass:[ZincArchiveExtractOperation class]];
        self.fileManager = [[[NSFileManager alloc] init] autorelease];
        self.cache = [[[NSCache alloc] init] autorelease];
        self.cache.countLimit = kZincRepoDefaultCacheCount;
        self.refreshInterval = kZincRepoDefaultAutoRefreshInterval;
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

- (ZincSerialQueueProxy*) indexProxy
{
    return (ZincSerialQueueProxy*)self.index;
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
    
    [blockself refreshSourcesWithCompletion:^{
        
        [blockself resumeBundleActions];

        [blockself refreshBundlesWithCompletion:^{
            
            [self checkForBundleDeletion];

            ZINC_DEBUG_LOG(@"tick");
            
        }];
    }];

//    @synchronized(self.myTasks) {
//        for (ZincTask* task in self.myTasks) {
//            if ([task isKindOfClass:[ZincBundleCloneTask class]]) {
//                ZINC_DEBUG_LOG(@"%@ : %f", task, task.progress);
//            }
//        }
//    }
    
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

- (ZincManifest*) loadManifestWithBundleIdentifier:(NSString*)bundleId version:(ZincVersion)version error:(NSError**)outError
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

- (ZincVersion) versionForBundleId:(NSString*)bundleId distribution:(NSString*)distro
{
    NSError* error = nil;
    NSString* catalogId = [ZincBundle catalogIdFromBundleId:bundleId];
    NSString* bundleName = [ZincBundle bundleNameFromBundleId:bundleId];
    ZincCatalog* catalog = [self catalogWithIdentifier:catalogId error:&error];
    if (catalog == nil) {
        [self logEvent:[ZincErrorEvent eventWithError:error source:self]];
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
    [self.indexProxy executeBlock:^{
        
        [self.index addTrackedBundleId:bundleId distribution:distro];
        [self queueIndexSave];
        
        ZincVersion version = [self versionForBundleId:bundleId distribution:distro];
        NSURL* bundleRes = [NSURL zincResourceForBundleWithId:bundleId version:version];
        ZincBundleState state = [self.index stateForBundle:bundleRes];
        
        if (state != ZincBundleStateCloning && state != ZincBundleStateAvailable) {
            [self.index setState:ZincBundleStateCloning forBundle:bundleRes];
            ZincTaskDescriptor* taskDesc = [ZincBundleCloneTask taskDescriptorForResource:bundleRes];
            [self queueTaskForDescriptor:taskDesc];
        }
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
            [self queueTaskForDescriptor:[ZincBundleCloneTask taskDescriptorForResource:bundleRes]];
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
            ZincVersion version = [self versionForBundleId:bundleId distribution:distro];
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
            
            ZincTaskDescriptor* taskDesc = [ZincBundleCloneTask taskDescriptorForResource:bundleRes];
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

- (ZincTask*) queueTaskForDescriptor:(ZincTaskDescriptor*)taskDescriptor input:(id)input dependencies:(NSArray*)dependencies
{
    @synchronized(self.myTasks) {
        
        NSArray* tasksMatchingResource = [self tasksForResource:taskDescriptor.resource];
        
        // look for an exact match
        ZincTask* existingTask = nil;
        for (ZincTask* resourceTask in tasksMatchingResource) {
            if ([[resourceTask taskDescriptor] isEqual:taskDescriptor]) {
                existingTask = resourceTask;
            }
        }
        
        ZincTask* task = nil;
        
        // if no exact match found, add task and depends for all other resource-matching
        if (existingTask == nil) {
            
            task = [ZincTask taskWithDescriptor:taskDescriptor repo:self input:input];
            
            for (ZincTask* resourceTask in tasksMatchingResource) {
                if (resourceTask != existingTask) {
                    [task addDependency:resourceTask];
                }
            }
            
            // !!!: special case for bundle clone tasks
            if ([existingTask isKindOfClass:[ZincBundleCloneTask class]]) {
                NSArray* deleteOps = [[self.queueGroup getQueueForClass:[ZincBundleDeleteTask class]]
                                      operations];
                
                for (NSOperation* deleteOp in deleteOps) {
                    [existingTask addDependency:deleteOp];
                }
            }
            
            [self.myTasks addObject:task];
            [task addObserver:self forKeyPath:@"isFinished" options:0 context:&kvo_taskIsFinished];
            [self addOperation:task];
            return task;
            
        } else {
            
            //ZINC_DEBUG_LOG(@"[Zincself.repo 0x%x] Task already exists! %@", (int)self, taskDescriptor);
            task = existingTask;
        }
        
        for (NSOperation* dep in dependencies) {
            [task addDependency:dep];
        }
        
        return task;
    }
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
            [foundTask removeObserver:self forKeyPath:@"isFinished"];
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
        
         [[NSNotificationCenter defaultCenter] postNotificationName:[[event class] notificationName] object:self userInfo:event.attributes];        
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
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end



