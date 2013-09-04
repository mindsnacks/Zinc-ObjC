//
//  Zinc.h
//  Zinc
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#ifndef _ZINC_GLOBALS_
#define _ZINC_GLOBALS_

extern NSString* const kZincPackageName;

typedef NSInteger ZincFormat;
typedef NSInteger ZincVersion;

enum  {
    ZincFormatInvalid = -1,
};

enum  {
    ZincVersionInvalid = -1,
    ZincVersionUnknown = 0,
};

typedef enum {
    ZincBundleStateNone      = 0,
    ZincBundleStateCloning   = 1,
    ZincBundleStateAvailable = 2,
    ZincBundleStateDeleting  = 3,
    ZincBundleStateInvalid   = -1,
} ZincBundleState;

extern NSString* const ZincBundleStateName[];

extern NSString* const ZincFileFormatRaw;
extern NSString* const ZincFileFormatGZ;

typedef void (^ZincCompletionBlock)(NSArray* errors);

#endif