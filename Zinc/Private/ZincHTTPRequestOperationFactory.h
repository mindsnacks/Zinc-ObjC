//
//  ZincHTTPRequestOperationFactory.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincHTTPRequestOperation.h"

@interface ZincHTTPRequestOperationFactory : NSObject

/**
 @discussion default is YES
 */
@property (atomic, assign) BOOL executeTasksInBackgroundEnabled;

- (id<ZincHTTPRequestOperation>)operationForRequest:(NSURLRequest *)request;

@end
