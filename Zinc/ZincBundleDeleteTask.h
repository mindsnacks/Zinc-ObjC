//
//  ZincBundleDeleteTask.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"
#import "Zinc.h"

@interface ZincBundleDeleteTask : ZincTask

@property (readonly) NSString* bundleId;
@property (readonly) ZincVersion version;

@end
