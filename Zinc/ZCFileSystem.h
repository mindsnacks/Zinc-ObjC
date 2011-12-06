//
//  ZCFileSystem.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Zinc.h"

@interface ZCFileSystem : NSObject

/* Always returns a reader for format 1
 */
+ (Class) fileSystemForFormat:(ZincFormat)format;

+ (ZCFileSystem*) fileSystemForWithURL:(NSURL*)url error:(NSError**)outError;

@property (nonatomic, retain, readonly) NSURL* url;

- (NSString*) pathForResource:(NSString*)path version:(ZincVersionMajor)version;


#pragma mark Utility
// Not exactly private, but not needed for normal use

+ (ZincFormat) readZincFormatFromURL:(NSURL*)url error:(NSError**)outError;

@end
