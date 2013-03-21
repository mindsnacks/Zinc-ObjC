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


// ----------------------------------------------------------------------------
#pragma mark Repo Formats

typedef NSInteger ZincFormat;

enum  {
    ZincFormatInvalid = -1,
};


// ----------------------------------------------------------------------------
#pragma mark Versions

typedef NSInteger ZincVersion;

enum  {
    ZincVersionInvalid = -1,
    ZincVersionUnknown = 0,
};


// ----------------------------------------------------------------------------
#pragma mark File Object Formats

extern NSString* const ZincFileFormatRaw;
extern NSString* const ZincFileFormatGZ;


// ----------------------------------------------------------------------------
#pragma mark Other Types

typedef void (^ZincCompletionBlock)(NSArray* errors);


// ----------------------------------------------------------------------------
#pragma mark Logging

#ifdef ZINC_DEBUG
    #define ZINC_DEBUG_LOG(fmt, ...) (NSLog(fmt, ##__VA_ARGS__));
#else
	#define ZINC_DEBUG_LOG(...)
#endif

#endif
