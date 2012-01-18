//
//  NSFileManager+Zinc.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Zinc)

+ (NSFileManager *) zinc_newFileManager;

- (BOOL) zinc_directoryExistsAtPath:(NSString*)path;
- (BOOL) zinc_directoryExistsAtURL:(NSURL*)url;

- (BOOL) zinc_createDirectoryIfNeededAtPath:(NSString*)path error:(NSError**)outError;
- (BOOL) zinc_createDirectoryIfNeededAtURL:(NSURL*)url error:(NSError**)outError;

- (NSString*) zinc_sha1ForPath:(NSString*)path;

- (BOOL) zinc_gzipInflate:(NSString*)sourcePath destination:(NSString*)destPath  error:(NSError**)outError;

@end
