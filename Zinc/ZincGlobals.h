//
//  Zinc.h
//  Zinc
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//


#define kZincPackageName @"com.mindsnacks.zinc"

typedef NSInteger ZincFormat;
typedef NSInteger ZincVersion;

enum  {
    ZincFormatInvalid = -1,
};

enum  {
    ZincVersionInvalid = -1,
};

#ifndef ZINC_DEBUG_LOG
    #define ZINC_DEBUG_LOG NSLog
#endif

