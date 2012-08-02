//
//  ZincJSONSerialization.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/1/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSUInteger ZincJSONReadingOptions;
typedef NSUInteger ZincJSONWritingOptions;

@interface ZincJSONSerialization : NSObject

+ (id)JSONObjectWithData:(NSData *)data options:(ZincJSONReadingOptions)opt error:(NSError **)error;

+ (NSData *)dataWithJSONObject:(id)obj options:(ZincJSONWritingOptions)opt error:(NSError **)error;

@end
