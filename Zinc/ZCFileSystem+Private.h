//
//  ZCFileSystem+Private.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

@class ZCManifest;

@interface ZCFileSystem ()

- (id) initWithURL:(NSURL*)url;

- (ZCManifest*) readManifestForVersion:(ZincVersion)version error:(NSError**)outError;

@end
