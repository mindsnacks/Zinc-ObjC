//
//  NSData+Zinc.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/1/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Zinc)

- (NSString*) zinc_sha1;

- (NSData*) zinc_gzipInflate;

- (BOOL) zinc_writeToFile:(NSString*)path atomically:(BOOL)useAuxiliaryFile createDirectories:(BOOL)createIntermediates skipBackup:(BOOL)skipBackup error:(NSError**)outError;

@end
