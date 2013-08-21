//
//  ZincTrackingRef.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZincGlobals.h"

@interface ZincTrackingInfo : NSObject

@property (nonatomic, copy) NSString* distribution;
@property (nonatomic, assign) ZincVersion version;
@property (nonatomic, copy) NSString* flavor;

+ (ZincTrackingInfo*) trackingInfoWithDistribution:(NSString*)distribution;

+ (ZincTrackingInfo*) trackingInfoWithDistribution:(NSString*)distribution
                                           version:(ZincVersion)version;


#pragma mark Coding

+ (ZincTrackingInfo*) trackingInfoFromDictionary:(NSDictionary*)dict;
- (NSDictionary*) dictionaryRepresentation;

@end
