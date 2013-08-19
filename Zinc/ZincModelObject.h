//
//  ZincModelObject.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/18/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZincModelObject : NSObject

- (NSData*) jsonRepresentation:(NSError**)outError;

#pragma mark Subclasses Must Override

- (NSDictionary*) dictionaryRepresentation;

@end
