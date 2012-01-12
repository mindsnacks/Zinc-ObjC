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

- (id)initWithRepo:(ZincRepo *)repo bundleId:(NSString*)bundleId version:(ZincVersion)version;

// TODO: readonly?
@property (nonatomic, retain) NSString* bundleId;
@property (nonatomic, assign) ZincVersion version;

@end
