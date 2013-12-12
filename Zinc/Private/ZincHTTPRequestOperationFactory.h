//
//  ZincHTTPRequestOperationFactory.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/12/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincHTTPRequestOperation.h"


@protocol ZincHTTPRequestOperationFactoryDelegate;


@interface ZincHTTPRequestOperationFactory : NSObject

@property (nonatomic, weak) id<ZincHTTPRequestOperationFactoryDelegate> delegate;

- (id<ZincHTTPRequestOperation>)operationForRequest:(NSURLRequest *)request;

@end



@protocol ZincHTTPRequestOperationFactoryDelegate <NSObject>

/**
 If not implemented, will default to YES
 */
- (BOOL)HTTPRequestOperationFactory:(ZincHTTPRequestOperationFactory *)operationRequestFactory shouldExecuteOperationsInBackground:(id<ZincHTTPRequestOperation>)operation;

@end