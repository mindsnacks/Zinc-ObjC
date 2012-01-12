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

- (id) initWithRepo:(ZincRepo *)repo bundleId:(NSString*)bundleId version:(ZincVersion)version;

// TODO: readonly?
@property (nonatomic, retain) NSString* bundleId;
@property (nonatomic, assign) ZincVersion version;



@end
