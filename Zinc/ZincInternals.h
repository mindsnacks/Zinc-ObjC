//
//  ZincInternals.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/18/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#ifndef Zinc_ObjC_ZincInternals_h
#define Zinc_ObjC_ZincInternals_h

// Common
#import "ZincGlobals.h"
#import "ZincErrors.h"
#import "ZincUtils.h"
#import "ZincJSONSerialization.h"
#import "ZincDeepCopying.h"
#import "NSError+Zinc.h"
#import "NSFileManager+Zinc.h"
#import "NSData+Zinc.h"

// Models
#import "ZincBundle.h"
#import "ZincSource.h"
#import "ZincCatalog.h"
#import "ZincManifest.h"
#import "ZincTask.h"
#import "ZincTaskDescriptor.h"
#import "ZincTaskRef.h"
#import "ZincTaskRequest.h"
#import "ZincTrackingInfo.h"
#import "ZincResource.h"
#import "ZincEvent.h"

// Tasks
#import "ZincArchiveDownloadTask.h"
#import "ZincArchiveExtractOperation.h"
#import "ZincBundleDeleteTask.h"
#import "ZincBundleRemoteCloneTask.h"
#import "ZincCatalogUpdateTask.h"
#import "ZincCleanLegacySymlinksTask.h"
#import "ZincCompleteInitializationTask.h"
#import "ZincGarbageCollectTask.h"
#import "ZincManifestDownloadTask.h"
#import "ZincObjectDownloadTask.h"
#import "ZincRepoIndexUpdateTask.h"
#import "ZincSourceUpdateTask.h"

#ifdef ZINC_DEBUG
#define ZINC_DEBUG_LOG(fmt, ...) (NSLog(fmt, ##__VA_ARGS__));
#else
#define ZINC_DEBUG_LOG(...)
#endif

#endif
