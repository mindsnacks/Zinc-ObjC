//
//  ZincHTTPStreamOperation.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 2/28/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincHTTPRequestOperation.h"

@interface ZincHTTPStreamOperation : ZincHTTPRequestOperation
{
@private
    CFHTTPMessageRef _response;
}

- (id) initWithURL:(NSURL*)url;

@property (retain, readonly) NSURL* url;

@end
