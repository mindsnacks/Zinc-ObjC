//
//  Zinc+NSString.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/14/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "NSString+Zinc.h"

@implementation NSString (Zinc)


// TODO: write tests for this
- (NSString*) zinc_realPath
{
    return [[self stringByResolvingSymlinksInPath]
            stringByStandardizingPath];
}


@end
