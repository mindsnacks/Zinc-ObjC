//
//  ZincGzip.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 10/19/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincGzip.h"
#import "ZincGlobals.h"
#import "ZincErrors.h"

#import <zlib.h>

#define DEFAULT_CHUNK_SIZE 16384

BOOL ZincGzipInflate(NSString* sourcePath, NSString* destPath, size_t bufferSize, NSError** outError)
{
    assert(bufferSize <= UINT_MAX);  // [self length] greater than UINT_MAX

    NSError* error = nil;

    CFURLRef inputURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                      (CFStringRef)sourcePath,
                                                      kCFURLPOSIXPathStyle,
                                                      false);
    
    CFURLRef outputURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                       (CFStringRef)destPath,
                                                       kCFURLPOSIXPathStyle,
                                                       false);
    
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    
    if (bufferSize == 0) bufferSize = DEFAULT_CHUNK_SIZE;
    
    uint8_t inputBuffer[bufferSize];
    uint8_t outputBuffer[bufferSize];
    
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, inputURL);
    if (readStream == NULL) {
        error = ZincErrorWithInfo(ZINC_ERR_READ_STREAM_CREATE, @{@"path" : sourcePath});
        goto done;
    }
    if (!CFReadStreamOpen(readStream)) {
        error = ZincErrorWithInfo(ZINC_ERR_READ_STREAM_OPEN, @{@"path" : sourcePath});
        goto done;
    }
    
    writeStream = CFWriteStreamCreateWithFile(kCFAllocatorDefault, outputURL);
    if (writeStream == NULL) {
        error = ZincErrorWithInfo(ZINC_ERR_WRITE_STREAM_CREATE, @{@"path" : destPath});
        goto done;
    }
    if (!CFWriteStreamOpen(writeStream)) {
        error = ZincErrorWithInfo(ZINC_ERR_WRITE_STREAM_OPEN, @{@"path" : destPath});
        goto done;
    }
    
    z_stream strm;
	strm.total_out = 0;
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
    
    if (inflateInit2(&strm, (15+32)) != Z_OK) {
        error = ZincError(ZINC_ERR_GZIP_INFLATE_INIT_FAIL);
        goto done;
    }
    
    int inflate_status;
	do
	{
        CFIndex bytesReadCount = CFReadStreamRead(readStream,
                                                  (uint8_t*)inputBuffer,
                                                  (CFIndex)sizeof(inputBuffer));
        strm.next_in = inputBuffer;
        strm.avail_in = (unsigned int)bytesReadCount;
        
        do {
            strm.next_out = outputBuffer;
            strm.avail_out = (unsigned int)bufferSize;
            
            inflate_status = inflate(&strm, Z_SYNC_FLUSH);
            if (inflate_status < 0) {
                
                // see: http://www.zlib.net/zlib_how.html
                
                assert(inflate_status != Z_STREAM_ERROR);  // This can only occur if the stream was not set up properly.
                
                switch (inflate_status) {
                    case Z_BUF_ERROR: // This is OK. The buffer will catch up next loop.
                        continue;
                        
                    default:
                        error = ZincErrorWithInfo(ZINC_ERR_GZIP_INFLATE_FAIL,
                                                  @{@"status": [NSNumber numberWithInt:inflate_status]});
                        goto done;

                }
            };
            
            CFIndex bytesToWriteCount = bufferSize - strm.avail_out;
            
            if (CFWriteStreamWrite(writeStream, outputBuffer, bytesToWriteCount) != bytesToWriteCount) {
                error = ZincError(ZINC_ERR_WRITE_STREAM_FAIL);
                goto done;
            }
            
        } while (strm.avail_out == 0);
	}
    while (inflate_status != Z_STREAM_END);
    
	if (inflateEnd (&strm) != Z_OK) {
        error = ZincError(ZINC_ERR_GZIP_INFLATE_END_FAIL);
        goto done;
    }
    
done:

    if (readStream != NULL) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (writeStream != NULL) {
        CFWriteStreamClose(writeStream);
        CFRelease(writeStream);
    }
    CFRelease(inputURL);
    CFRelease(outputURL);
    
    if (error != nil && outError != NULL) {
        *outError = error;
    }
    
    return (error == nil);
}