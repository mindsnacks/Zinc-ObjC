//
//  ZincManifestUpdateOperation.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadTask.h"
#import "ZincGlobals.h"

@class ZincRepo;

@interface ZincManifestDownloadTask : ZincDownloadTask

@property (readonly) NSString* bundleId;
@property (readonly) ZincVersion version;

@end
