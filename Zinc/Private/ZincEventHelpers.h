//
//  ZincEventHelpers.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZincHTTPRequestOperation;


@interface ZincEventHelpers : NSObject

+ (NSDictionary *)attributesForRequestOperation:(id<ZincHTTPRequestOperation>)op;

@end
