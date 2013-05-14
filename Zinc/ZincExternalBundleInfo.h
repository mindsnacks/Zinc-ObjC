//
//  ZincRepoExternalBundleRef.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/15/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZincExternalBundleInfo : NSObject

+ (ZincExternalBundleInfo*) infoForBundleResource:(NSURL*)resource manifestPath:(NSString*)manifestPath bundleRootPath:(NSString*)bundleRootPath;

@property (nonatomic, strong) NSURL* bundleResource;

@property (nonatomic, strong) NSString* manifestPath;
@property (nonatomic, strong) NSString* bundleRootPath;

@end
