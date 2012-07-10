//
//  Zinc.h
//  Zinc
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#ifndef _ZINC_GLOBALS_
#define _ZINC_GLOBALS_

#define kZincPackageName @"com.mindsnacks.zinc"

typedef NSInteger ZincFormat;
typedef NSInteger ZincVersion;

enum  {
    ZincFormatInvalid = -1,
};

enum  {
    ZincVersionInvalid = -1,
};

extern NSString* const ZincFileFormatRaw;
extern NSString* const ZincFileFormatGZ;

#ifdef ZINC_DEBUG
    #define ZINC_DEBUG_LOG(fmt, ...) (NSLog(fmt, ##__VA_ARGS__));
#else
	#define ZINC_DEBUG_LOG(...)
#endif

#endif
