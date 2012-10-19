
//
//  NSFileManager+Zinc.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "NSFileManager+Zinc.h"
#import "NSData+Zinc.h"
#import "NSError+Zinc.h"
#import "ZincSHA.h"

@implementation NSFileManager (Zinc)

+ (NSFileManager *) zinc_newFileManager
{
    return [[[NSFileManager alloc] init] autorelease];
}

- (BOOL) zinc_directoryExistsAtPath:(NSString*)path
{
    BOOL isDir;
    BOOL result = [self fileExistsAtPath:path isDirectory:&isDir];
    return result && isDir;
}

- (BOOL) zinc_directoryExistsAtURL:(NSURL*)url
{
    return [self zinc_directoryExistsAtPath:[url path]];
}

- (BOOL) zinc_createDirectoryIfNeededAtPath:(NSString*)path error:(NSError**)outError
{
//    if (![self zinc_directoryExistsAtPath:path]) {
        if (![self createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:outError]) {
            return NO;
//        }
    }
    return YES;
}

- (BOOL) zinc_createDirectoryIfNeededAtURL:(NSURL*)url error:(NSError**)outError
{
    return [self zinc_createDirectoryIfNeededAtPath:[url path] error:outError];
}

- (NSString*) zinc_sha1ForPath:(NSString*)path
{
    NSString* sha = (NSString*)ZincSHA1HashCreateWithPath((CFStringRef)path, 0);
    return [sha autorelease];
}

- (BOOL) zinc_gzipInflate:(NSString*)sourcePath destination:(NSString*)destPath  error:(NSError**)outError
{
    NSData* compressed = [[[NSData alloc] initWithContentsOfFile:sourcePath options:0 error:outError] autorelease];
    if (compressed == nil) return NO;
                    
    NSData* uncompressed = [compressed zinc_gzipInflate];
    if (![uncompressed writeToFile:destPath options:0 error:outError]) {
        return NO;
    }

    return YES;
}

- (BOOL) zinc_removeItemAtPath:(NSString*)path error:(NSError**)outError
{
    NSError* error = nil;
    if (![self removeItemAtPath:path error:&error]) {
        if (![error zinc_isFileNotFoundError]) {
            if (outError != NULL) *outError = error;
            return NO;
        }
    }
    return YES;
}


@end
