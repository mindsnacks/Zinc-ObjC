//
//  NSFileManager+Zinc.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "NSFileManager+Zinc.h"

@implementation NSFileManager (Zinc)

+ (NSFileManager *) zinc_newFileManager
{
    return [[[NSFileManager alloc] init] autorelease];
}

@end
