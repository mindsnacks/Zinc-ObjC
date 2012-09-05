//
//  NSError+Zinc.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/29/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "NSError+Zinc.h"

@implementation NSError (Zinc)

- (BOOL) zinc_isFileNotFoundError
{
    return self.domain == NSCocoaErrorDomain &&
               (self.code == NSFileNoSuchFileError ||
                self.code == NSFileReadNoSuchFileError);
}

@end
