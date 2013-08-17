//
//  ZCBundleManager.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincRepoAgent+Private.h"
#import "ZincRepoIndex.h"
#import "ZincBundle.h"
#import "ZincBundle+Private.h"
#import "ZincManifest.h"
#import "ZincSource.h"
#import "ZincCatalog.h"
#import "ZincEvent.h"
#import "ZincEvent+Private.h"
#import "ZincResource.h"
#import "ZincTask+Private.h"
#import "ZincTaskDescriptor.h"
#import "ZincRepoIndexUpdateTask.h"
#import "ZincArchiveExtractOperation.h"
#import "ZincOperationQueueGroup.h"
#import "ZincUtils.h"
#import "NSFileManager+Zinc.h"
#import "NSData+Zinc.h"
#import "ZincJSONSerialization.h"
#import "ZincErrors.h"
#import "ZincTrackingInfo.h"
#import "ZincTaskRef.h"
#import "ZincBundleTrackingRequest.h"
#import "NSError+Zinc.h"
#import "ZincTaskActions.h"
#import "ZincExternalBundleInfo.h"
#import "ZincRepoBundleManager.h"
#import "ZincTasks.h"

#import <KSReachability/KSReachability.h>


#define CATALOGS_DIR @"catalogs"
#define MANIFESTS_DIR @"manifests"
#define FILES_DIR @"objects"
#define BUNDLES_DIR @"bundles"
#define DOWNLOADS_DIR @"zinc/downloads"
#define REPO_INDEX_FILE @"repo.json"


NSString* const ZincRepoBundleStatusChangeNotification = @"ZincRepoBundleStatusChangeNotification";
NSString* const ZincRepoBundleWillDeleteNotification = @"ZincRepoBundleWillDeleteNotification";
NSString* const ZincRepoBundleDidBeginTrackingNotification = @"ZincRepoBundleDidBeginTrackingNotification";
NSString* const ZincRepoBundleWillStopTrackingNotification = @"ZincRepoBundleWillStopTrackingNotification";

NSString* const ZincRepoBundleChangeNotificationBundleIDKey = @"bundleID";
NSString* const ZincRepoBundleChangeNotifiationStatusKey = @"status";

NSString* const ZincRepoTaskAddedNotification = @"ZincRepoTaskAddedNotification";
NSString* const ZincRepoTaskFinishedNotification = @"ZincRepoTaskFinishedNotification";

NSString* const ZincRepoTaskNotificationTaskKey = @"task";

@interface ZincRepo ()

@property (nonatomic, strong) NSURL* url;

// runtime state
@property (nonatomic, strong, readwrite) ZincRepoAgent *agent;
@property (nonatomic, strong) NSMutableDictionary* sourcesByCatalog;
@property (nonatomic, strong) NSCache* cache;
@property (nonatomic, strong) NSMutableDictionary* localFilesBySHA;
@property (nonatomic, assign, readwrite) BOOL isInitialized;
@property (nonatomic, strong) ZincRepoBundleManager* bundleManager;

@end


@implementation ZincRepo

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL error:(NSError**)outError
{
    NSOperationQueue* operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setMaxConcurrentOperationCount:kZincRepoDefaultNetworkOperationCount];
    return [self repoWithURL:fileURL networkOperationQueue:operationQueue error:outError];
}

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue error:(NSError**)outError
{
    if ([[[fileURL path] lastPathComponent] isEqualToString:REPO_INDEX_FILE]) {
        fileURL = [NSURL fileURLWithPath:[[fileURL path] stringByDeletingLastPathComponent]];
    }
    
    KSReachability* reachability = [KSReachability reachabilityToLocalNetwork];
    
    ZincRepo* repo = [[ZincRepo alloc] initWithURL:fileURL networkOperationQueue:networkQueue reachability:reachability];
    if (![repo createDirectoriesIfNeeded:outError]) {
        return nil;
    }
    
    NSString* indexPath = [[fileURL path] stringByAppendingPathComponent:REPO_INDEX_FILE];
    if ([repo.fileManager fileExistsAtPath:indexPath]) {
        
        NSData* jsonData = [[NSData alloc] initWithContentsOfFile:indexPath options:0 error:outError];
        if (jsonData == nil) {
            return nil;
        }
        
        NSDictionary* jsonDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:outError];
        if (jsonDict == nil) {
            return nil;
        }
        
        ZincRepoIndex* index = [ZincRepoIndex repoIndexFromDictionary:jsonDict error:outError];
        if (index == nil) {
            return nil;
        }
        repo.index = index;
    }

    if (![repo queueInitializationTasks]) {
        repo.isInitialized = YES;
    }
    
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

- (id) initWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)networkQueue reachability:(KSReachability*)reachability
{
    self = [super init];
    if (self) {
        self.url = fileURL;
        self.index = [[ZincRepoIndex alloc] init];
        self.fileManager = [[NSFileManager alloc] init];
        self.cache = [[NSCache alloc] init];
        self.cache.countLimit = kZincRepoDefaultCacheCount;
        self.sourcesByCatalog = [NSMutableDictionary dictionary];
        self.reachability = reachability;
        self.localFilesBySHA = [NSMutableDictionary dictionary];
        self.bundleManager = [[ZincRepoBundleManager alloc] initWithZincRepo:self];
        self.taskManager = [[ZincRepoTaskManager alloc] initWithZincRepo:self networkOperationQueue:networkQueue];
        self.agent = [[ZincRepoAgent alloc] initWithRepo:self];
    }
    return self;
}

/**
 @discussion Returns YES if initialization tasks are queued, NO otherwise
 */
- (BOOL) queueInitializationTasks
{
    NSAssert(!self.isInitialized, @"should not already be initialized");

    ZincCompleteInitializationTask* completeInitializationTask = nil;
    NSMutableArray* initOps = [NSMutableArray arrayWithCapacity:1];
    
    // Check for v1 -> v2 migration
    if (self.index.format == 1) {
        ZincCleanLegacySymlinksTask* cleanSymlinksTask = [[ZincCleanLegacySymlinksTask alloc] initWithRepo:self resourceDescriptor:[self url]];
        cleanSymlinksTask.completionBlock = ^{
            self.index.format = 2;
            [self queueIndexSaveTask];
        };
        [initOps addObject:cleanSymlinksTask];
        [self.taskManager addOperation:cleanSymlinksTask];
    }
    
    if ([initOps count] > 0) {
        completeInitializationTask = [[ZincCompleteInitializationTask alloc] initWithRepo:self resourceDescriptor:self.url];
        
        for (NSOperation* initOp in initOps) {
            [completeInitializationTask addDependency:initOp];
        }
        [self.taskManager addOperation:completeInitializationTask];
    }
    
    return completeInitializationTask != nil;
}


- (ZincTaskRef*) taskRefForInitialization
{
    @synchronized(self) {

        if (self.isInitialized) {
            return nil;
        }

        return [self.taskManager taskRefForInitialization];
    }
}

- (void) waitForInitialization
{
    [[self taskRefForInitialization] waitUntilFinished];
}

- (void) completeInitialization
{
    self.isInitialized = YES;
}

- (void) setReachability:(KSReachability*)reachability
{
    if (_reachability == reachability) return;
    
    if (_reachability != nil) {
        _reachability.onReachabilityChanged = nil;
    }
    
    _reachability = reachability;
        
    if (_reachability != nil) {

        __weak typeof(self) weakself = self;
        
        _reachability.onReachabilityChanged = ^(KSReachability *reachability) {

            __strong typeof(weakself) strongself = weakself;
            
            @synchronized(strongself.taskManager.tasks) {
                NSArray* remoteBundleUpdateTasks = [strongself.taskManager.tasks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                    return [evaluatedObject isKindOfClass:[ZincBundleRemoteCloneTask class]];
                }]];
                [remoteBundleUpdateTasks makeObjectsPerformSelector:@selector(updateReadiness)];
            }
            
            [strongself.agent refreshWithCompletion:nil];
        };
    }
}

- (void)dealloc
{
    [self suspendAllTasksAndWaitExecutingTasksToComplete];

    // set to nil to unsubscribe from notitifcations
    self.reachability = nil;
}

#pragma mark Notifications

- (void) postNotification:(NSString*)notificationName userInfo:(NSDictionary*)userInfo
{
    // NOTE: intentionally capturing `self` here to prevent the repo from being
    // deallocated before the notification fires.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                            object:self
                                                          userInfo:userInfo];
    }];
}

- (void) postNotification:(NSString*)notificationName bundleID:(NSString*)bundleID state:(ZincBundleState)state
{
    NSDictionary* userInfo = @{ZincRepoBundleChangeNotificationBundleIDKey: bundleID,
                              ZincRepoBundleChangeNotifiationStatusKey: @(state)};
    [self postNotification:notificationName userInfo:userInfo];
}

- (void) postNotification:(NSString*)notificationName bundleID:(NSString*)bundleID
{
    NSDictionary* userInfo = @{ZincRepoBundleChangeNotificationBundleIDKey: bundleID};
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

- (NSString*) pathForManifestWithBundleID:(NSString*)identifier version:(ZincVersion)version
{
    NSURL* bundleRes = [NSURL zincResourceForBundleWithID:identifier version:version];
    ZincExternalBundleInfo* extInfo = [self.index infoForExternalBundle:bundleRes];
    if (extInfo != nil) {
        return extInfo.manifestPath;
    }
    
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

- (NSString*) externalPathForFileWithSHA:(NSString*)sha
{
    NSString* path = nil;
    @synchronized(self.localFilesBySHA) {
        path = self.localFilesBySHA[sha];
    }
    return path;
}



#pragma mark Sources

- (void) addSourceURL:(NSURL*)source
{
    [self.index addSourceURL:source];
    [self queueIndexSaveTask];
    
    ZincTaskDescriptor* taskDesc = [ZincSourceUpdateTask taskDescriptorForResource:source];
    [self.taskManager queueTaskForDescriptor:taskDesc];
}

- (void) removeSourceURL:(NSURL*)source
{
    @synchronized(self.sourcesByCatalog) {
        for (NSString* catalogID in [self.sourcesByCatalog allKeys]) {
            NSMutableArray* sources = (self.sourcesByCatalog)[catalogID];
            [sources removeObject:source];
        }
    }
    
    [self.index removeSourceURL:source];
    [self queueIndexSaveTask];
}

- (NSSet*) sourceURLs
{
    return [self.index sourceURLs];
}

- (void) registerSource:(NSURL*)source forCatalog:(ZincCatalog*)catalog
{
    @synchronized(self.sourcesByCatalog) {
        NSMutableArray* sources = (self.sourcesByCatalog)[catalog.identifier];
        if (sources == nil) {
            sources = [NSMutableArray array];
            (self.sourcesByCatalog)[catalog.identifier] = sources;
        }
        // TODO: cleaner duplicate check
        for (NSURL* existingSource in sources) {
            if ([existingSource isEqual:source]) {
                return;
            }
        }
        [sources addObject:source];
        [self.cache setObject:catalog forKey:[self cacheKeyForCatalogID:catalog.identifier]];
    }
}

- (NSArray*) sourcesForCatalogID:(NSString*)catalogID
{
    return (self.sourcesByCatalog)[catalogID];
}

#pragma mark Caching

- (NSString*) cacheKeyForCatalogID:(NSString*)identifier
{
    return [@"Catalog:" stringByAppendingString:identifier];
}

- (NSString*) cacheKeyManifestWithBundleID:(NSString*)identifier version:(ZincVersion)version
{
    return [[@"Manifest:" stringByAppendingString:identifier] stringByAppendingFormat:@"-%d", version];
}

- (NSString*) cacheKeyForBundleID:(NSString*)identifier version:(ZincVersion)version
{
    return [[@"Bundle:" stringByAppendingString:identifier] stringByAppendingFormat:@"-%d", version];
}

#pragma mark Repo Index

- (ZincTask*) queueIndexSaveTask
{
    ZincTaskDescriptor* taskDesc = [ZincRepoIndexUpdateTask taskDescriptorForResource:[self indexURL]];
    return [self.taskManager queueTaskForDescriptor:taskDesc];
}

#pragma mark Catalogs

- (void) registerCatalog:(ZincCatalog*)catalog
{
    NSString* key = [self cacheKeyForCatalogID:catalog.identifier];
    [self.cache setObject:catalog forKey:key];
}

- (ZincCatalog*) loadCatalogWithIdentifier:(NSString*)identifier error:(NSError**)outError
{
    NSString* catalogPath = [[[self catalogsPath] stringByAppendingPathComponent:identifier] stringByAppendingPathExtension:@"json"];
    NSData* jsonData = [NSData dataWithContentsOfFile:catalogPath options:0 error:outError];
    if (jsonData == nil) {
        return nil;
    }
    NSDictionary* jsonDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:outError];
    if (jsonDict == nil) {
        return nil;
    }
    ZincCatalog* catalog = [[ZincCatalog alloc] initWithDictionary:jsonDict];
    return catalog;
}

- (ZincCatalog*) catalogWithIdentifier:(NSString*)identifier error:(NSError**)outError
{
    NSString* key = [self cacheKeyForCatalogID:identifier];
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

- (void) addManifest:(ZincManifest*)manifest forBundleID:(NSString*)bundleID
{
    NSString* cacheKey = [self cacheKeyManifestWithBundleID:bundleID version:manifest.version];
    [self.cache setObject:manifest forKey:cacheKey];
}

- (BOOL) removeManifestForBundleID:(NSString*)bundleID version:(ZincVersion)version error:(NSError**)outError
{
    NSString* manifestPath = [self pathForManifestWithBundleID:bundleID version:version];
    if (![self.fileManager zinc_removeItemAtPath:manifestPath error:outError]) {
        return NO;
    }
    [self.cache removeObjectForKey:[self cacheKeyManifestWithBundleID:bundleID version:version]];
    return YES;
}

- (BOOL) hasManifestForBundleIDentifier:(NSString*)bundleID version:(ZincVersion)version
{
    NSString* path = [self pathForManifestWithBundleID:bundleID version:version];
    return [self.fileManager fileExistsAtPath:path];
}

- (ZincManifest*) importManifestWithPath:(NSString*)manifestPath error:(NSError**)outError
{
    // read manifest
    NSData* jsonData = [NSData dataWithContentsOfFile:manifestPath options:0 error:outError];
    if (jsonData == nil) {
        return nil;
    }
    
    // copy manifest to repo
    NSDictionary* manifestDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:outError];
    ZincManifest* manifest = [[ZincManifest alloc] initWithDictionary:manifestDict];
    NSString* manifestRepoPath = [self pathForManifestWithBundleID:manifest.bundleID version:manifest.version];
    
    BOOL shouldCopy = NO;
    if (manifest.version == 0) {  // version 0 always needs to be re-written
        [self.fileManager removeItemAtPath:manifestRepoPath error:NULL];
        shouldCopy = YES;
    } else if (![self.fileManager fileExistsAtPath:manifestRepoPath]) {
        shouldCopy = YES;
    }
    
    if (shouldCopy) {
        if (![self.fileManager copyItemAtPath:manifestPath toPath:manifestRepoPath error:outError]) {
            return nil;
        }
    }
    
    return manifest;
}

- (ZincManifest*) loadManifestWithBundleID:(NSString*)bundleID version:(ZincVersion)version error:(NSError**)outError
{
    NSString* manifestPath = [self pathForManifestWithBundleID:bundleID version:version];
    NSData* jsonData = [NSData dataWithContentsOfFile:manifestPath options:0 error:outError];
    if (jsonData == nil) {
        return nil;
    }
    NSDictionary* jsonDict = [ZincJSONSerialization JSONObjectWithData:jsonData options:0 error:outError];
    if (jsonDict == nil) {
        return nil;
    }
    ZincManifest* manifest = [[ZincManifest alloc] initWithDictionary:jsonDict];
    return manifest;
}

- (ZincManifest*) manifestWithBundleID:(NSString*)bundleID version:(ZincVersion)version error:(NSError**)outError
{
    NSString* key = [self cacheKeyManifestWithBundleID:bundleID version:version];
    ZincManifest* manifest = [self.cache objectForKey:key];
    if (manifest == nil) {
        manifest = [self loadManifestWithBundleID:bundleID version:version error:outError];
        if (manifest != nil) {
            [self.cache setObject:manifest forKey:key];
        }
    }
    return manifest;
}

- (NSSet*) activeBundles
{
    NSMutableSet* activeBundles = [NSMutableSet set];
    
    @synchronized(self.index) {
        NSSet* trackBundles = [self.index trackedBundleIDs];
        for (NSString* bundleID in trackBundles) {
            NSString* dist = [self.index trackedDistributionForBundleID:bundleID];
            ZincVersion version = [self versionForBundleID:bundleID distribution:dist];
            [activeBundles addObject:[NSURL zincResourceForBundleWithID:bundleID version:version]];
        }
        
        [activeBundles addObjectsFromArray:[self.index registeredExternalBundles]];
    }

    NSSet* loadedBundles = [self.bundleManager activeBundles];
    [activeBundles addObjectsFromArray:[loadedBundles allObjects]];

    return activeBundles;
}


- (ZincVersion) catalogVersionForBundleID:(NSString*)bundleID distribution:(NSString*)distro
{
    NSParameterAssert(bundleID);
    NSParameterAssert(distro);
    
    NSError* error = nil;
    
    NSString* catalogID = [ZincBundle catalogIDFromBundleID:bundleID];
    ZincCatalog* catalog = [self catalogWithIdentifier:catalogID error:&error];
    if (catalog != nil) {
        NSString* bundleName = [ZincBundle bundleNameFromBundleID:bundleID];
        ZincVersion catalogVersion = [catalog versionForBundleID:bundleName distribution:distro];
        
        if (catalogVersion == ZincVersionInvalid) {
            NSDictionary* info = @{@"bundleID" : bundleID, @"distro": distro};
            NSError* error = ZincErrorWithInfo(ZINC_ERR_DISTRO_NOT_FOUND_IN_CATALOG, info);
            [self logEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
        }
        
        return catalogVersion;
    }
    
    return ZincVersionInvalid;
}

- (ZincVersion) versionForBundleID:(NSString*)bundleID distribution:(NSString*)distro
{
    NSArray* availableVersions = [self.index availableVersionsForBundleID:bundleID];
    
    if ([availableVersions count] == 0) {
        return ZincVersionInvalid;
    }
    
    if (distro != nil) {
        ZincVersion catalogVersion = [self catalogVersionForBundleID:bundleID distribution:distro];
        if ([availableVersions containsObject:@(catalogVersion)]) {
            return catalogVersion;
        }
    }
    
    return [[availableVersions lastObject] integerValue];
}

- (BOOL) hasManifestForBundleID:(NSString *)bundleID distribution:(NSString*)distro
{
    NSString* catalogID = [ZincBundle catalogIDFromBundleID:bundleID];
    NSString* bundleName = [ZincBundle bundleNameFromBundleID:bundleID];
    ZincCatalog* catalog = [self catalogWithIdentifier:catalogID error:NULL];
    if (catalog == nil) {
        return NO;
    }
    ZincVersion version = [catalog versionForBundleID:bundleName distribution:distro];
    return [self hasManifestForBundleIDentifier:bundleID version:version];
}

- (void) registerLocalFilesFromExternalManifest:(ZincManifest*)manifest bundleRootPath:(NSString*)bundleRoot
{
    @synchronized(self.localFilesBySHA) {
        NSArray* allFiles = [manifest allFiles];
        for (NSString* f in allFiles) {
            NSString* sha = [manifest shaForFile:f];
            self.localFilesBySHA[sha] = [bundleRoot stringByAppendingPathComponent:f];
        }
    }
}

- (BOOL) registerExternalBundleWithManifestPath:(NSString*)manifestPath bundleRootPath:(NSString*)rootPath error:(NSError**)outError
{
    ZincManifest* manifest = [ZincManifest manifestWithPath:manifestPath error:outError];
    if (manifestPath == nil) {
        return NO;
    }
    
    BOOL isDir;
    if (![self.fileManager fileExistsAtPath:rootPath isDirectory:&isDir] || !isDir) {
        if (outError != NULL) *outError = ZincError(ZINC_ERR_INVALID_DIRECTORY);
        return NO;
    }
    
    NSURL* bundleRes = [NSURL zincResourceForBundleWithID:manifest.bundleID version:manifest.version];
    @synchronized(self.index) {
        [self.index registerExternalBundle:bundleRes manifestPath:manifestPath bundleRootPath:rootPath];
        [self registerLocalFilesFromExternalManifest:manifest bundleRootPath:rootPath];
    }
    
    return YES;
}

- (void) beginTrackingBundleWithRequest:(ZincBundleTrackingRequest*)req
{
    NSParameterAssert(req);
    [self beginTrackingBundleWithID:req.bundleID distribution:req.distribution flavor:req.flavor automaticallyUpdate:req.updateAutomatically];
}

- (void) beginTrackingBundleWithID:(NSString*)bundleID distribution:(NSString*)distro automaticallyUpdate:(BOOL)autoUpdate
{
    NSParameterAssert(bundleID);
    NSParameterAssert(distro);
    [self beginTrackingBundleWithID:bundleID distribution:distro flavor:nil automaticallyUpdate:autoUpdate];
}

- (void) beginTrackingBundleWithID:(NSString*)bundleID distribution:(NSString*)distro flavor:(NSString*)flavor automaticallyUpdate:(BOOL)autoUpdate
{
    NSString* catalogID = ZincCatalogIDFromBundleID(bundleID);
    if (catalogID == nil) {
        [NSException raise:NSInvalidArgumentException
                    format:@"does not appear to be a valid bundle id"];
    }
    
    if (distro == nil) {
        [NSException raise:NSInvalidArgumentException
                    format:@"distro must not be nil"];
    }
    
    @synchronized(self.index) {
        ZincTrackingInfo* trackingInfo = [self.index trackingInfoForBundleID:bundleID];
        if (trackingInfo == nil) {
            trackingInfo = [[ZincTrackingInfo alloc] init];
        }
        
        if (trackingInfo.flavor != nil && ![trackingInfo.flavor isEqualToString:flavor]) {
            @throw [NSException
                    exceptionWithName:NSInternalInconsistencyException
                    reason:[NSString stringWithFormat:@"currently cannot re-track a different flavor"]
                    userInfo:nil];
        } else {
            trackingInfo.flavor = flavor;
        }
        
        trackingInfo.distribution = distro;
        trackingInfo.updateAutomatically = autoUpdate;
        if (autoUpdate) {
            trackingInfo.version = [self catalogVersionForBundleID:bundleID distribution:distro];
        }
        [self.index setTrackingInfo:trackingInfo forBundleID:bundleID];
    }
    
    [self queueIndexSaveTask];
    [self postNotification:ZincRepoBundleDidBeginTrackingNotification bundleID:bundleID];
}

- (ZincTaskRef*) updateBundleWithID:(NSString*)bundleID
{
    ZincTaskRef* taskRef = [[ZincTaskRef alloc] init];
    [self updateBundleWithID:bundleID taskRef:taskRef];
    return taskRef;
}

- (void) updateBundleWithID:(NSString*)bundleID completionBlock:(ZincCompletionBlock)completion
{
    ZincTaskRef* taskRef = nil;
    if (completion != nil) {
        taskRef = [[ZincTaskRef alloc] init];
        __weak typeof(taskRef) weak_taskRef = taskRef;
        taskRef.completionBlock = ^{
            __strong typeof(weak_taskRef) strong_taskRef = weak_taskRef;
            completion([strong_taskRef allErrors]);
        };
    }
    [self updateBundleWithID:bundleID taskRef:taskRef];
}

- (void) updateBundleWithID:(NSString*)bundleID taskRef:(ZincTaskRef*)taskRef
{
    NSParameterAssert(bundleID);
    NSParameterAssert(taskRef);
    
    @synchronized(self.index) {
        
        ZincTrackingInfo* trackingInfo = [self.index trackingInfoForBundleID:bundleID];
        if (trackingInfo == nil) {
            NSDictionary* info = @{@"bundleID" : bundleID};
            NSError* error = ZincErrorWithInfo(ZINC_ERR_NO_TRACKING_DISTRO_FOR_BUNDLE, info);
            [self logEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
            if (taskRef != nil) {
                [taskRef addError:error];
                [self.taskManager addOperation:taskRef];  // queue the operation so the completion block gets executed
            }
            return;
        }
        
        ZincVersion version = [self catalogVersionForBundleID:bundleID distribution:trackingInfo.distribution];
        if (version == ZincVersionInvalid) {
            NSDictionary* info = @{@"bundleID" : bundleID};
            NSError* error = ZincErrorWithInfo(ZINC_ERR_BUNDLE_NOT_FOUND_IN_CATALOGS, info);
            [self logEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
            if (taskRef != nil) {
                [taskRef addError:error];
                [self.taskManager addOperation:taskRef]; // queue the operation so the completion block gets executed
            }
            return;
        }
        
        trackingInfo.version = version;
        [self.index setTrackingInfo:trackingInfo forBundleID:bundleID];
        
        NSURL* bundleRes = [NSURL zincResourceForBundleWithID:bundleID version:version];
        
        ZincBundleState state = [self.index stateForBundle:bundleRes];
        if (state != ZincBundleStateAvailable) {
            [self.index setState:ZincBundleStateCloning forBundle:bundleRes];
            ZincTaskDescriptor* taskDesc = [ZincBundleRemoteCloneTask taskDescriptorForResource:bundleRes];
            ZincTask* task = [self.taskManager queueTaskForDescriptor:taskDesc];
            
            if (taskRef != nil) {
                [taskRef addDependency:task];
                [self.taskManager addOperation:taskRef];
            }
        }
    }
    
    [self queueIndexSaveTask];
}

- (void) stopTrackingBundleWithID:(NSString*)bundleID
{
    [self postNotification:ZincRepoBundleWillStopTrackingNotification bundleID:bundleID];
    @synchronized(self.index) {
        [self.index removeTrackedBundleID:bundleID];
    }
    [self queueIndexSaveTask];
}

- (NSSet*) trackedBundleIDs
{
    return [self.index trackedBundleIDs];
}

#pragma mark Bundles

- (void) registerBundle:(NSURL*)bundleResource status:(ZincBundleState)status
{
    @synchronized(self.index) {
        [self.index setState:status forBundle:bundleResource];
    }
    [self postNotification:ZincRepoBundleStatusChangeNotification bundleID:[bundleResource zincBundleID] state:status];
    [self queueIndexSaveTask];
}

- (void) deregisterBundle:(NSURL*)bundleResource completion:(dispatch_block_t)completion
{
    [self postNotification:ZincRepoBundleWillDeleteNotification bundleID:[bundleResource zincBundleID]];
    @synchronized(self.index) {
        [self.index removeBundle:bundleResource];
    }
    ZincTask* saveTask = [self queueIndexSaveTask];
    if (completion != nil) {
        ZincTaskRef* taskRef = [[ZincTaskRef alloc] init];
        [taskRef addDependency:saveTask];
        taskRef.completionBlock = completion;
        [self.taskManager addOperation:taskRef];
    }
}

- (void) deregisterBundle:(NSURL*)bundleResource
{
    [self deregisterBundle:bundleResource completion:nil];
}

- (NSString*) pathForBundleWithID:(NSString*)bundleID version:(ZincVersion)version
{
    NSURL* bundleRes = [NSURL zincResourceForBundleWithID:bundleID version:version];
    ZincExternalBundleInfo* extInfo = [self.index infoForExternalBundle:bundleRes];
    if (extInfo != nil) {
        return extInfo.bundleRootPath;
    }

    NSString* bundleDirName = [NSString stringWithFormat:@"%@-%d", bundleID, version];
    NSString* bundlePath = [[self bundlesPath] stringByAppendingPathComponent:bundleDirName];
    return bundlePath;
}


- (ZincBundle*) bundleWithID:(NSString*)bundleID
{
    if (!self.isInitialized) {
        @throw [NSException
                exceptionWithName:NSInternalInconsistencyException
                reason:[NSString stringWithFormat:@"repo not initialized"]
                userInfo:nil];
    }

    NSString* distro = [self.index trackedDistributionForBundleID:bundleID];
    ZincVersion version = [self versionForBundleID:bundleID distribution:distro];
    if (version == ZincVersionInvalid) {
        return nil;
    }

    return [self.bundleManager bundleWithID:bundleID version:version];
}

- (ZincBundleState) stateForBundleWithID:(NSString*)bundleID
{
    @synchronized(self.index) {
        NSString* distro = [self.index trackedDistributionForBundleID:bundleID];
        ZincVersion version = [self versionForBundleID:bundleID distribution:distro];
        NSURL* bundleRes = [NSURL zincResourceForBundleWithID:bundleID version:version];
        ZincBundleState state = [self.index stateForBundle:bundleRes];
        return state;
    }
}


#pragma mark Tasks

- (NSArray*) tasks
{
    return [NSArray arrayWithArray:self.taskManager.tasks];
}

- (void) suspendAllTasks
{
    [self.taskManager suspendAllTasks];
}

- (void) suspendAllTasksAndWaitExecutingTasksToComplete
{
    [self.taskManager suspendAllTasksAndWaitExecutingTasksToComplete];
}

- (void) resumeAllTasks
{
    [self.taskManager resumeAllTasks];
}

- (BOOL) isSuspended
{
    return [self.taskManager isSuspended];
}

- (void)cleanWithCompletion:(dispatch_block_t)completion
{
    ZincTaskRef* taskRef = [[ZincTaskRef alloc] init];
    ZincTask* garbageTask = [self queueGarbageCollectTask];
    [taskRef addDependency:garbageTask];
    taskRef.completionBlock = completion;
    [self.taskManager addOperation:taskRef];
}

- (ZincTask*) queueGarbageCollectTask
{
    ZincTaskDescriptor* taskDesc = [ZincGarbageCollectTask taskDescriptorForResource:self.url];
    return [self.taskManager queueTaskForDescriptor:taskDesc];
}

- (ZincTask*) queueCleanSymlinksTask
{
    ZincTaskDescriptor* taskDesc = [ZincCleanLegacySymlinksTask taskDescriptorForResource:self.url];
    return [self.taskManager queueTaskForDescriptor:taskDesc];
}

- (void) logEvent:(ZincEvent*)event
{
    __weak typeof(self) weakself = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        __strong typeof(weakself) strongself = weakself;
        if ([strongself.delegate respondsToSelector:@selector(zincRepo:didReceiveEvent:)])
            [strongself.delegate zincRepo:strongself didReceiveEvent:event];
        
        NSMutableDictionary* userInfo = [event.attributes mutableCopy];
        [[NSNotificationCenter defaultCenter] postNotificationName:[[event class] notificationName] object:self userInfo:userInfo];
    }];
}

+ (void)setDefaultThreadPriority:(double)defaultThreadPriority
{
    [ZincOperation setDefaultThreadPriority:defaultThreadPriority];
}



@end



