//
//  ZincArchiveDownloadTask.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadTask.h"
#import "ZincGlobals.h"

@interface ZincArchiveDownloadTask : ZincDownloadTask

@property (readonly) NSString* bundleID;
@property (readonly) ZincVersion version;

@end
