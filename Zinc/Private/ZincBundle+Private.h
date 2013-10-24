//
//  ZCBundle+Private.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincBundle.h"

@class ZincRepoBundleManager;

@interface ZincBundle ()

- (id) initWithRepoBundleManager:(ZincRepoBundleManager*)bundleManager bundleID:(NSString*)bundleID version:(ZincVersion)version bundleURL:(NSURL*)bundleURL;

@end