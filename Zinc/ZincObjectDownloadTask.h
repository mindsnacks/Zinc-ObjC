//
//  ZincFileUpdateTask2.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincDownloadTask.h"

@interface ZincObjectDownloadTask : ZincDownloadTask

@property (readonly) NSString* sha;

@property (readonly) NSInteger bytesRead;
@property (readonly) NSInteger totalBytesToRead;

@end
