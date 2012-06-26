//
//  ZincBundleCloneTask.h
//  
//
//  Created by Andy Mroczkowski on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZincTask.h"
#import "ZincGlobals.h"

@interface ZincBundleCloneTask : ZincTask

@property (readonly) NSString* bundleId;
@property (readonly) ZincVersion version;

@end
