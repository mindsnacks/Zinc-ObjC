//
//  NSData+Zinc.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/1/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "NSData+Zinc.h"
#import "sha1.h"


@implementation NSData (Zinc)

- (NSString*) zinc_sha1
{
    uint8_t* buffer = (uint8_t*)[self bytes];
    NSUInteger remaining = [self length];
    
    SHA1_CTX context;
    SHA1Init(&context);

//#define SHA_READ_BUFFER_SIZE (16384)
//    while (remaining > 0) {
//        NSUInteger chunkSize = MIN(remaining, SHA_READ_BUFFER_SIZE);
//        SHA1Update(&context, buffer, chunkSize);
//        remaining -= chunkSize;
//        buffer += chunkSize;
//    }
    
    SHA1Update(&context, buffer, remaining);
    unsigned char digest[20];
    SHA1Final(digest, &context);
    
    char finalhash[40];
    char hexval[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
    for(int j = 0; j < 20; j++){
        finalhash[j*2] = hexval[((digest[j] >> 4) & 0xF)];
        finalhash[(j*2) + 1] = hexval[(digest[j]) & 0x0F];
    }
    
    NSString* sha = [[[NSString alloc] initWithBytes:finalhash length:40 encoding:NSUTF8StringEncoding] autorelease];
    return sha;
}

@end
