//
//  ZincArchiveDownloadTask.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"
#import "ZincGlobals.h"

@interface ZincArchiveDownloadTask : ZincTask

@property (readonly) NSString* bundleId;
@property (readonly) ZincVersion version;

@end
