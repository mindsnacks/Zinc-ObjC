//
//  ZincSHA.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 10/19/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>

#ifndef Zinc_ObjC_ZincSHA_h
#define Zinc_ObjC_ZincSHA_h

extern CFStringRef ZincSHA1HashCreateWithPath(CFStringRef filePath,
                                             size_t chunkSizeForReadingData);

#endif
