//
//  ZincManifestUpdateOperation.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"
#import "Zinc.h"

@class ZincRepo;

@interface ZincManifestDownloadTask : ZincTask

- (id)initWithRepo:(ZincRepo*)repo bundleId:(NSString*)bundleId version:(ZincVersion)version;

@property (nonatomic, retain) NSString* bundleId;
@property (nonatomic, assign) ZincVersion version;

@end
