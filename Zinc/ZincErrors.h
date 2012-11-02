//
//  ZincErrors.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#define kZincErrorDomain kZincPackageName

#define ZincError(E) AMError(E, kZincErrorDomain)
#define ZincErrorWithInfo(E,I) AMErrorWithInfo(E,kZincErrorDomain,I) 

enum 
{
    ZINC_ERR_INVALID_DIRECTORY                    = 1001,
    ZINC_ERR_COULD_NOT_OPEN_FILE                  = 1002,
    ZINC_ERR_DECOMPRESS_FAILED                    = 1101,
    ZINC_ERR_SHA_MISMATCH                         = 1102,
    
    ZINC_ERR_READ_STREAM_CREATE                   = 1201,
    ZINC_ERR_READ_STREAM_OPEN                     = 1202,
    ZINC_ERR_READ_STREAM_FAIL                     = 1203,
    
    ZINC_ERR_WRITE_STREAM_CREATE                  = 1301,
    ZINC_ERR_WRITE_STREAM_OPEN                    = 1302,
    ZINC_ERR_WRITE_STREAM_FAIL                    = 1303,
    
    ZINC_ERR_MISSING_INDEX_FILE                   = 2001,
    ZINC_ERR_INVALID_FORMAT                       = 2002,
    ZINC_ERR_INVALID_REPO_FORMAT                  = 2101,
    ZINC_ERR_INVALID_MANIFEST_FORMAT              = 2102,
    ZINC_ERR_NO_TRACKING_DISTRO_FOR_BUNDLE        = 2103,
    
    ZINC_ERR_NO_SOURCES_FOR_CATALOG               = 3101,
    ZINC_ERR_BUNDLE_NOT_FOUND_IN_CATALOGS         = 3102,
    ZINC_ERR_DISTRO_NOT_FOUND_IN_CATALOG          = 3103,
    
    ZINC_ERR_BOOTSTRAP_FAILED                     = 5101,
    ZINC_ERR_BOOTSTRAP_MANIFEST_NOT_FOUND         = 5102,
    
    ZINC_ERR_GZIP_INFLATE_INIT_FAIL               = 6001,
    ZINC_ERR_GZIP_INFLATE_FAIL                    = 6002,
    ZINC_ERR_GZIP_INFLATE_END_FAIL                = 6003,

    ZINC_ERR_UNKNOWN                              = 99999,
};