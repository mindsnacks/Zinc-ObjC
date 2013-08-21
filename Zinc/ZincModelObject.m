//
//  ZincModelObject.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/18/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincModelObject.h"

@implementation ZincModelObject

- (NSDictionary*) dictionaryRepresentation
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSData*) jsonRepresentation:(NSError**)outError
{
    return [NSJSONSerialization dataWithJSONObject:[self dictionaryRepresentation] options:0 error:outError];
}

@end
