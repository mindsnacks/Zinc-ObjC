//
//  ZCIndex.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/16/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"
#import "ZincModelObject.h"

@interface ZincCatalog : ZincModelObject

- (id) init;

@property (nonatomic, strong, readonly) NSString* identifier;
@property (nonatomic, assign) ZincFormat format;
@property (nonatomic, strong, readonly) NSDictionary* bundleInfoById;

#pragma mark -
- (ZincVersion) versionForBundleID:(NSString*)bundleName distribution:(NSString*)distro;

#pragma mark Encoding
- (id) initWithDictionary:(NSDictionary*)dict;

@end

// TODO: rename, break out, etc
@interface ZincCatalog (JSON)

+ (ZincCatalog*) catalogFromJSONData:(NSData*)data error:(NSError**)outError;

@end