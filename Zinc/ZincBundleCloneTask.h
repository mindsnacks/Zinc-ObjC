//
//  ZincBundleUpdateOperation.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"
#import "Zinc.h"

@interface ZincBundleCloneTask : ZincTask

@property (readonly) NSString* bundleId;
@property (readonly) ZincVersion version;

@end
