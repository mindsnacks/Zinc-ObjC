//
//  ZincErrors.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#define kZincErrorDomain kZincPackageName

#define ZCError(E) AMError(E, kZincErrorDomain)
#define ZCErrorWithInfo(E,I) AMErrorWithInfo(E,kZincErrorDomain,I) 

typedef void (^ZCBasicBlock)(id result, id context, NSError* error);

enum 
{
    ZINC_ERR_MISSING_FORMAT_FILE                  = 1001,
    ZINC_ERR_INVALID_FORMAT                       = 1002,
    ZINC_ERR_INVALID_MANIFEST_FORMAT              = 1101,
    ZINC_ERR_UNKNOWN                              = 99999,
};