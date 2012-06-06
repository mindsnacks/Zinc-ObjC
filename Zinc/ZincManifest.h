//
//  ZCManifest.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincGlobals.h"

@interface ZincManifest : NSObject

- (id) init;
- (id) initWithDictionary:(NSDictionary*)dict;

@property (nonatomic, retain) NSString* bundleId;
@property (nonatomic, assign) ZincVersion version;

- (NSString*) shaForFile:(NSString*)path;
- (NSArray*) formatsForFile:(NSString*)path;
- (NSString*) bestFormatForFile:(NSString*)path withPreferredFormats:(NSArray*)formats;
- (NSString*) bestFormatForFile:(NSString*)path;
- (NSUInteger) sizeForFile:(NSString*)path format:(NSString*)format;

- (NSArray*) allFiles;
- (NSArray*) allSHAs;
- (NSUInteger) fileCount;

- (NSDictionary*) dictionaryRepresentation;
- (NSString*) jsonRepresentation:(NSError**)outError;

@end
