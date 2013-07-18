
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

@implementation NSFileManager (Zinc)

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
    if (![self createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:outError]) {
        return NO;
    }
    return YES;
}

- (BOOL) zinc_createDirectoryIfNeededAtURL:(NSURL*)url error:(NSError**)outError
{
    return [self zinc_createDirectoryIfNeededAtPath:[url path] error:outError];
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

- (BOOL) zinc_moveItemAtPath:(NSString*)srcPath toPath:(NSString*)dstPath failIfExists:(BOOL)failIfExists error:(NSError**)error
{
    NSError* myError = nil;
    BOOL success = [self moveItemAtPath:srcPath toPath:dstPath error:&myError];
    if (!success &&
        !failIfExists &&
        [myError.domain isEqualToString:NSCocoaErrorDomain] &&
        myError.code == NSFileWriteFileExistsError)
    {
        return YES;
    }

    if (error != NULL) {
        *error = myError;
    }

    return success;
}

- (BOOL) zinc_moveItemAtPath:(NSString*)srcPath toPath:(NSString*)dstPath error:(NSError**)error
{
    return [self zinc_moveItemAtPath:srcPath toPath:dstPath failIfExists:NO error:error];
}

@end
