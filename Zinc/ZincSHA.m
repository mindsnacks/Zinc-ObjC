//
//  ZincSHA.c
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 10/19/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

// Adapted from http://www.joel.lopes-da-silva.com/2010/09/07/compute-md5-or-sha-hash-of-large-file-efficiently-on-ios-and-mac-os-x/

#include "ZincSHA.h"
#include <CommonCrypto/CommonDigest.h>
#import "ZincGlobals.h"
#import "ZincErrors.h"

#define DEFAULT_CHUNK_SIZE 4096

NSString* ZincSHA1HashFromPath(NSString* filePath, size_t chunkSize, NSError** outError)
{
    NSError* error = nil;
    CFURLRef fileURL = NULL;
    CFReadStreamRef readStream = NULL;
    
    // Make sure chunkSize is valid
    if (chunkSize == 0) {
        chunkSize = DEFAULT_CHUNK_SIZE;
    }

    uint8_t buffer[chunkSize];

    fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                            (CFStringRef)filePath,
                                            kCFURLPOSIXPathStyle,
                                            (Boolean)false);    
    
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (readStream == NULL) {
        error = ZincErrorWithInfo(ZINC_ERR_READ_STREAM_CREATE, @{@"path" : filePath});
        goto done;
    }
    
    if (!CFReadStreamOpen(readStream)) {
        error = ZincErrorWithInfo(ZINC_ERR_READ_STREAM_OPEN, @{@"path" : filePath});
        goto done;
    }
    
    CC_SHA1_CTX hashObject;
    CC_SHA1_Init(&hashObject);
    
    
    while (1) {
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) {
            error = ZincError(ZINC_ERR_READ_STREAM_FAIL);
            goto done;
            
        } else if (readBytesCount == 0) {
            break;
        }
        
        CC_SHA1_Update(&hashObject,
                       (const void *)buffer,
                       (CC_LONG)readBytesCount);
    }
    
    // Compute the hash digest
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_Final(digest, &hashObject);
    
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    
done:
    if (readStream != NULL) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL != NULL) {
        CFRelease(fileURL);
    }
    
    if (error != nil && outError != NULL) {
        *outError = error;
    }
    
    if (error != nil) return nil;

    return [[[NSString alloc] initWithCString:hash encoding:NSUTF8StringEncoding] autorelease];
}