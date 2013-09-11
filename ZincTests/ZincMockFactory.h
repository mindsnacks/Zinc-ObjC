//
//  ZincMockFactory.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/10/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"

@interface ZincMockFactory : NSObject

- (id) mockBundleCloneTaskForBundleID:(NSString*)bundleID version:(ZincVersion)version;

@end
