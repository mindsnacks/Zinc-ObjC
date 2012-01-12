//
//  ZincResourceDescriptor.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Zinc.h"

@protocol ZincResourceDescriptor <NSObject, NSCopying>
- (id)copy;
@end

@interface ZincCatalogDescriptor : NSObject <ZincResourceDescriptor>
+ (id) catalogDescriptorForId:(NSString*)catalogId;
@property (nonatomic, retain) NSString* catalogId;
@end

@interface ZincManifestDescriptor : NSObject <ZincResourceDescriptor>
+ (id) manifestDescriptorForId:(NSString*)bundleId version:(ZincVersion)version;
@property (nonatomic, retain) NSString* bundleId;
@property (nonatomic, assign) ZincVersion version;
@end

@interface ZincFileDescriptor : NSObject <ZincResourceDescriptor>
+ (id) fileDescriptorForSHA:(NSString*)sha;
@property (nonatomic, retain) NSString* sha;
@end
