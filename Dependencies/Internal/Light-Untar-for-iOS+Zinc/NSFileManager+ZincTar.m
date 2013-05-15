//
//  NSFileManager+Tar.m
//  Tar
//
//  Created by Mathieu Hausherr Octo Technology on 25/11/11.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "NSFileManager+ZincTar.h"
#import "ZincGlobals.h"
#import "ZincErrors.h"
#include <fcntl.h>

#pragma mark - Definitions

// Login mode
// Comment this line for production
//#define TAR_VERBOSE_LOG_MODE

// const definition
#define TAR_BLOCK_SIZE 512
#define TAR_TYPE_POSITION 156
#define TAR_NAME_POSITION 0
#define TAR_NAME_SIZE 100
#define TAR_SIZE_POSITION 124
#define TAR_SIZE_SIZE 12

#define TAR_MAX_BLOCK_LOAD_IN_MEMORY 100

// Error const
#define TAR_ERROR_DOMAIN [kZincPackageName stringByAppendingString:@".lightuntar"]
#define TAR_ERROR_CODE_BAD_BLOCK 1
#define TAR_ERROR_CODE_SOURCE_NOT_FOUND 2
#define TAR_ERROR_CODE_BAD_FILE 3

#define TAR_ERROR_FILE_PATH_ERROR_KEY @"path"

#pragma mark - Private Methods
@interface NSFileManager (ZincTar_Private)
-(BOOL)zinc_createFilesAndDirectoriesAtPath:(NSString *)path withTarObject:(id)object size:(unsigned long long)size error:(NSError **)error;
- (BOOL)zinc_writeFileDataForObject:(id)object inRange:(NSRange)range atPath:(NSString*)path error:(NSError**)outError;
@end

@interface ZincNSFileManagerTarHelper : NSObject
+ (char)typeForObject:(id)object atOffset:(unsigned long long)offset;
+ (NSString*)nameForObject:(id)object atOffset:(unsigned long long)offset;
+ (unsigned long long)sizeForObject:(id)object atOffset:(unsigned long long)offset;
+ (NSData*)dataForObject:(id)object inRange:(NSRange)range;
@end

#pragma mark - Implementation
@implementation NSFileManager (ZincTar)

- (BOOL)zinc_createFilesAndDirectoriesAtURL:(NSURL*)url withTarData:(NSData*)tarData error:(NSError**)error
{
    return[self zinc_createFilesAndDirectoriesAtPath:[url path] withTarData:tarData error:error];
}

- (BOOL)zinc_createFilesAndDirectoriesAtPath:(NSString*)path withTarData:(NSData*)tarData error:(NSError**)error
{
    return [self zinc_createFilesAndDirectoriesAtPath:path withTarObject:tarData size:[tarData length] error:error];
}

-(BOOL)zinc_createFilesAndDirectoriesAtPath:(NSString *)path withTarPath:(NSString *)tarPath error:(NSError **)error
{
    NSFileManager * filemanager = [NSFileManager defaultManager];
    if([filemanager fileExistsAtPath:tarPath]){
        NSDictionary * attributes = [filemanager attributesOfItemAtPath:tarPath error:nil];        
        unsigned long long size = [[attributes objectForKey:NSFileSize] unsignedLongLongValue];
        
        NSFileHandle* fileHandle = [NSFileHandle fileHandleForReadingAtPath:tarPath];
        BOOL result = [self zinc_createFilesAndDirectoriesAtPath:path withTarObject:fileHandle size:size error:error];
        [fileHandle closeFile];
        return result;
    }
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: @"Source file not found",
                               TAR_ERROR_FILE_PATH_ERROR_KEY: path
                               };

    if (error != NULL) *error = [NSError errorWithDomain:TAR_ERROR_DOMAIN code:TAR_ERROR_CODE_SOURCE_NOT_FOUND userInfo:userInfo];
    return NO;
}

-(BOOL)zinc_createFilesAndDirectoriesAtPath:(NSString *)path withTarObject:(id)object size:(unsigned long long)size error:(NSError **)error
{
    if (size % TAR_BLOCK_SIZE != 0) {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: @"Invalid tar file",
                                   TAR_ERROR_FILE_PATH_ERROR_KEY: path
                                   };

        if (error != NULL) *error = [NSError errorWithDomain:TAR_ERROR_DOMAIN code:TAR_ERROR_CODE_BAD_FILE userInfo:userInfo];
        return NO;
    }
    
    if (![self createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:error]) {
        return NO;
    }
        
    long location = 0; // Position in the file
    while (location<size) {       
        long blockCount = 1; // 1 block for the header
        
        switch ([ZincNSFileManagerTarHelper typeForObject:object atOffset:location]) {
            case '0': // It's a File
            {                
                NSString* name = [ZincNSFileManagerTarHelper nameForObject:object atOffset:location];
#ifdef TAR_VERBOSE_LOG_MODE
                NSLog(@"UNTAR - file - %@",name);  
#endif
                NSString *filePath = [path stringByAppendingPathComponent:name]; // Create a full path from the name
                
                long size = [ZincNSFileManagerTarHelper sizeForObject:object atOffset:location];
                
                if (size == 0){
#ifdef TAR_VERBOSE_LOG_MODE
                    NSLog(@"UNTAR - empty_file - %@", filePath);
#endif
                    if (![@"" writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:error]) {
                        return NO;
                    }
                    break;
                }

                blockCount += (size-1)/TAR_BLOCK_SIZE+1; // size/TAR_BLOCK_SIZE rounded up
                
                if (![self zinc_writeFileDataForObject:object inRange:NSMakeRange(location+TAR_BLOCK_SIZE, size) atPath:filePath error:error]) {
                    return NO;
                }
                break;
            }
            case '5': // It's a directory
            {
                NSString* name = [ZincNSFileManagerTarHelper nameForObject:object atOffset:location];
#ifdef TAR_VERBOSE_LOG_MODE
                NSLog(@"UNTAR - directory - %@",name); 
#endif
                NSString *directoryPath = [path stringByAppendingPathComponent:name]; // Create a full path from the name
                if (![self createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:error]) {
                    return NO;
                }
                break;
            }
            case '\0': // It's a nul block
            {
#ifdef TAR_VERBOSE_LOG_MODE
                NSLog(@"UNTAR - empty block"); 
#endif
                break;
            }
            case '1':
            case '2':
            case '3':
            case '4':
            case '6':
            case '7':
            case 'x':
            case 'g': // It's not a file neither a directory
            {
#ifdef TAR_VERBOSE_LOG_MODE
                NSLog(@"UNTAR - unsupported block"); 
#endif
                long size = [ZincNSFileManagerTarHelper sizeForObject:object atOffset:location];
                blockCount += (size-1)/TAR_BLOCK_SIZE+1; // size/TAR_BLOCK_SIZE rounded up
                break;
            }          
            default: // It's not a tar type
            {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: @"Invalid block type found",
                                           TAR_ERROR_FILE_PATH_ERROR_KEY: path
                                           };
                if (error != NULL) *error = [NSError errorWithDomain:TAR_ERROR_DOMAIN code:TAR_ERROR_CODE_BAD_BLOCK userInfo:userInfo];
                return NO;
            }
        }
        
        location+=blockCount*TAR_BLOCK_SIZE;
    }
    return YES;
}

- (BOOL)zinc_writeFileDataForObject:(id)object inRange:(NSRange)range atPath:(NSString*)path error:(NSError **)outError
{
    if([object isKindOfClass:[NSData class]]) {
        NSData *data = (NSData *)object;
        NSData *rangedData = [data subdataWithRange:range];
        return [rangedData writeToFile:path options:0 error:outError];
    }
    else if([object isKindOfClass:[NSFileHandle class]]) {
        
        int fd = open([path fileSystemRepresentation], O_CREAT|O_WRONLY, S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP);
        if (fd > 0) {
            NSFileHandle *destinationFile = [[NSFileHandle alloc] initWithFileDescriptor:fd];
            [object seekToFileOffset:range.location];
            
            int maxSize = TAR_MAX_BLOCK_LOAD_IN_MEMORY*TAR_BLOCK_SIZE;
            while(range.length > maxSize) {
                [destinationFile writeData:[object readDataOfLength:maxSize]];
                range = NSMakeRange(range.location+maxSize,range.length-maxSize);
            }
            [destinationFile writeData:[object readDataOfLength:range.length]];
            [destinationFile closeFile];
            
        } else {
            if (outError != NULL) {
                *outError = ZincErrorWithInfo(ZINC_ERR_COULD_NOT_OPEN_FILE, @{@"path" : path});
            }
            
            return NO;
        }
    }
    return YES;
}

@end


@implementation ZincNSFileManagerTarHelper

+ (char)typeForObject:(id)object atOffset:(unsigned long long)offset
{
    char type;
    memcpy(&type,[self dataForObject:object inRange:NSMakeRange(offset+TAR_TYPE_POSITION, 1)].bytes, 1);
    return type;
}

+ (NSString*)nameForObject:(id)object atOffset:(unsigned long long)offset
{
    char nameBytes[TAR_NAME_SIZE+1]; // TAR_NAME_SIZE+1 for nul char at end
    memset(&nameBytes, '\0', TAR_NAME_SIZE+1); // Fill byte array with nul char
    memcpy(&nameBytes,[self dataForObject:object inRange:NSMakeRange(offset+TAR_NAME_POSITION, TAR_NAME_SIZE)].bytes, TAR_NAME_SIZE);
    return [NSString stringWithCString:nameBytes encoding:NSASCIIStringEncoding];
}

+ (unsigned long long)sizeForObject:(id)object atOffset:(unsigned long long)offset
{
    char sizeBytes[TAR_SIZE_SIZE+1]; // TAR_SIZE_SIZE+1 for nul char at end
    memset(&sizeBytes, '\0', TAR_SIZE_SIZE+1); // Fill byte array with nul char
    memcpy(&sizeBytes,[self dataForObject:object inRange:NSMakeRange(offset+TAR_SIZE_POSITION, TAR_SIZE_SIZE)].bytes, TAR_SIZE_SIZE);
    return strtol(sizeBytes, NULL, 8); // Size is an octal number, convert to decimal
}

+ (NSData*)dataForObject:(id)object inRange:(NSRange)range
{
    if([object isKindOfClass:[NSData class]]) {
        return [object subdataWithRange:range];
    }
    else if([object isKindOfClass:[NSFileHandle class]]) {
        [object seekToFileOffset:range.location];
        return [object readDataOfLength:range.length];
    }
    return nil;
}

@end