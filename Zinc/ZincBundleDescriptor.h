//
//  ZincBundleDescriptor.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Zinc.h"
#import "ZincResourceDescriptor.h"

@interface ZincBundleDescriptor : NSObject <ZincResourceDescriptor>

+ (id) bundleDescriptorForId:(NSString*)bundleId version:(ZincVersion)version;

@property (nonatomic, retain) NSString* bundleId;
@property (nonatomic, assign) ZincVersion version;

@end
