//
//  ZCIndex.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/16/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Zinc.h"

@interface ZCIndex : NSObject

- (id) init;

@property (nonatomic, assign) ZincFormat format;
@property (nonatomic, retain) NSDictionary* bundles;
@property (nonatomic, retain) NSDictionary* distributions;


#pragma mark Encoding
- (id) initWithDictionary:(NSDictionary*)dict;
- (NSDictionary*) dictionaryRepresentation;

@end
