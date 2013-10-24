//
//  ZincBundleDeleteTask.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"
#import "ZincGlobals.h"

@interface ZincBundleDeleteTask : ZincTask

@property (readonly) NSString* bundleID;
@property (readonly) ZincVersion version;

@end
