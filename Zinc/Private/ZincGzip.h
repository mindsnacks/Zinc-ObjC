//
//  ZincGzip.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 10/19/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

extern BOOL ZincGzipInflate(NSString* sourcePath, NSString* destPath, size_t chunkSize, NSError** outError);
