//
//  ZincURLSessionNSURLSessionImpl.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/13/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincURLSession.h"

#if defined(__IPHONE_7_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0

@interface NSURLSession (ZincURLSession) <ZincURLSession>

@end

@interface NSURLSessionTask (ZincURLSessionTask) <ZincURLSessionTask>

@end

#endif