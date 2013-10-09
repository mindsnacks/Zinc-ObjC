//
//  ZincDownloadTask.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/30/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"

@interface ZincDownloadTask : ZincTask

@property (readonly) long long bytesRead;
@property (readonly) long long totalBytesToRead;

@end
