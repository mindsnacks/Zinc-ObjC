//
//  ZincManifestUpdateOperation.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask2.h"
#import "Zinc.h"

@class ZincClient;

@interface ZincManifestUpdateOperation : ZincTask2

- (id)initWithClient:(ZincClient *)client bundleIdentifier:(NSString*)bundleId version:(ZincVersion)version;

@property (nonatomic, retain) NSString* bundleId;
@property (nonatomic, assign) ZincVersion version;

@end
