//
//  ZincHTTPStreamOperation.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 2/28/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincURLConnectionOperation.h"

@interface ZincHTTPStreamOperation : ZincURLConnectionOperation
{
@private
    CFHTTPMessageRef _response;
}

- (id) initWithURL:(NSURL*)url;

@property (retain, readonly) NSURL* url;

#pragma mark Cribbbed

/**
 The output stream that is used to write data received until the request is finished.
 
 @discussion By default, data is accumulated into a buffer that is stored into `responseData` upon completion of the request. When `outputStream` is set, the data will not be accumulated into an internal buffer, and as a result, the `responseData` property of the completed request will be `nil`. The output stream will be scheduled in the network thread runloop upon being set.
 */
@property (nonatomic, strong) NSOutputStream *outputStream;

@end
