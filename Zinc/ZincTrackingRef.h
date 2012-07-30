//
//  ZincTrackingRef.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZincGlobals.h"

@interface ZincTrackingRef : NSObject

@property (nonatomic, copy) NSString* distribution;
@property (nonatomic, assign) ZincVersion version;
@property (nonatomic, assign) BOOL updateAutomatically;

+ (ZincTrackingRef*) trackingRefWithDistribution:(NSString*)distribution
                             updateAutomatically:(BOOL)updateAutomatically;

+ (ZincTrackingRef*) trackingRefWithDistribution:(NSString*)distribution
                                         version:(ZincVersion)version;


#pragma mark Coding

+ (ZincTrackingRef*) trackingRefFromDictionary:(NSDictionary*)dict;
- (NSDictionary*) dictionaryRepresentation;

@end
