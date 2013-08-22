//
//  ZincBundleUpdateOperation.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"
#import "ZincGlobals.h"

#define kZincBundleCloneTaskDefaultHTTPOverheadConstant (100000)

#import "ZincBundleCloneTask.h"

@interface ZincBundleRemoteCloneTask : ZincBundleCloneTask

@property (assign) float httpOverheadConstant;

@end
