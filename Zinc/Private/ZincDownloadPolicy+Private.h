//
//  ZincDownloadPolicy+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 4/16/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincDownloadPolicy.h"

@interface ZincDownloadPolicy ()

- (ZincConnectionType) requiredConnectionTypeForBundleID:(NSString*)bundleID;

- (BOOL) doRulesAllowBundleID:(NSString*)bundleID;

@end