//
//  ZincBundleUpdateOperation.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"
#import "ZincGlobals.h"

#define kZincBundleCloneTaskDefaultHTTPOverheadConstant (1000)//(0.5)

@interface ZincBundleCloneTask : ZincTask

@property (readonly) NSString* bundleId;
@property (readonly) ZincVersion version;

@property (assign) float httpOverheadConstant;

@end
