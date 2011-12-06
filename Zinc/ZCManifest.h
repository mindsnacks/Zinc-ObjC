//
//  ZCManifest.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Zinc.h"

@interface ZCManifest : NSObject

- (id) initWithDictionary:(NSDictionary*)dict;

- (NSString*) version;
- (ZincVersionMajor) majorVersion;
- (ZincVersionMinor) minorVersion;
- (NSString*) shaForPath:(NSString*)path;

@end
