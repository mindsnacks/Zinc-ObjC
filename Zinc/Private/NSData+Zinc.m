//
//  NSData+Zinc.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/1/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "NSData+Zinc.h"
#import "ZincUtils.h"
#import "NSFileManager+Zinc.h"
#import <CommonCrypto/CommonDigest.h>
#include <zlib.h>

@implementation NSData (Zinc)

- (NSString*) zinc_sha1
{
    NSAssert([self length] <= UINT32_MAX, @"[self length] greater than CC_LONG capacity (UINT32_MAX)");

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([self bytes], (CC_LONG)[self length], digest);
    
    char finalhash[40];
    char hexval[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
    for(int j = 0; j < 20; j++){
        finalhash[j*2] = hexval[((digest[j] >> 4) & 0xF)];
        finalhash[(j*2) + 1] = hexval[(digest[j]) & 0x0F];
    }
    
    NSString* sha = [[NSString alloc] initWithBytes:finalhash length:40 encoding:NSUTF8StringEncoding];
    return sha;
}

// from http://www.cocoadev.com/index.pl?NSDataCategory
//- (NSData*) zinc_gzipDeflate
//{
//	if ([self length] == 0) return self;
//	
//	z_stream strm;
//	
//	strm.zalloc = Z_NULL;
//	strm.zfree = Z_NULL;
//	strm.opaque = Z_NULL;
//	strm.total_out = 0;
//	strm.next_in=(Bytef *)[self bytes];
//	strm.avail_in = [self length];
//	
//	// Compresssion Levels:
//	//   Z_NO_COMPRESSION
//	//   Z_BEST_SPEED
//	//   Z_BEST_COMPRESSION
//	//   Z_DEFAULT_COMPRESSION
//	
//	if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
//	
//	NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
//	
//	do {
//		
//		if (strm.total_out >= [compressed length])
//			[compressed increaseLengthBy: 16384];
//		
//		strm.next_out = [compressed mutableBytes] + strm.total_out;
//		strm.avail_out = [compressed length] - strm.total_out;
//		
//		deflate(&strm, Z_FINISH);  
//		
//	} while (strm.avail_out == 0);
//	
//	deflateEnd(&strm);
//	
//	[compressed setLength: strm.total_out];
//	return [NSData dataWithData:compressed];
//}

// from http://www.cocoadev.com/index.pl?NSDataCategory
- (NSData*) zinc_gzipInflate
{
	if ([self length] == 0) return self;

    NSAssert([self length] <= UINT_MAX, @"[self length] greater than UINT_MAX");

	const unsigned int full_length = (unsigned int)[self length];
	const unsigned int half_length = (unsigned int)[self length] / 2;

    NSAssert(full_length + half_length <= UINT_MAX, @"decompressed_length greater than UINT_MAX");

	NSMutableData *decompressed = [NSMutableData dataWithLength:full_length + half_length];
	BOOL done = NO;
	int status;
	
	z_stream strm;
	strm.next_in = (Bytef *)[self bytes];
	strm.avail_in = (unsigned int)[self length];
	strm.total_out = 0;
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	
	if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
	while (!done)
	{
		// Make sure we have enough room and reset the lengths.
		if (strm.total_out >= [decompressed length])
			[decompressed increaseLengthBy: half_length];
		strm.next_out = [decompressed mutableBytes] + strm.total_out;
		strm.avail_out = (unsigned int)([decompressed length] - strm.total_out);
		
		// Inflate another chunk.
		status = inflate (&strm, Z_SYNC_FLUSH);
		if (status == Z_STREAM_END) done = YES;
		else if (status != Z_OK) break;
	}
	if (inflateEnd (&strm) != Z_OK) return nil;
	
	// Set real length.
	if (done)
	{
		[decompressed setLength: strm.total_out];
		return [NSData dataWithData: decompressed];
	}
	else return nil;
}

- (BOOL) zinc_writeToFile:(NSString*)path
               atomically:(BOOL)atomically
        createDirectories:(BOOL)createDirectories
               skipBackup:(BOOL)skipBackup
                    error:(NSError**)outError
{
    NSDataWritingOptions options = 0;
    if (atomically) options = NSDataWritingAtomic;
    
    if (createDirectories) {
        NSFileManager* fm = [[NSFileManager alloc] init];
        if (![fm zinc_createDirectoryIfNeededAtPath:[path stringByDeletingLastPathComponent] error:outError]) {
            return NO;
        }
    }
    
    if (![self writeToFile:path options:options error:outError]) {
        return NO;
    }
    
    if (skipBackup) {
        ZincAddSkipBackupAttributeToFileWithPath(path);
    }
    return YES;

}


@end
