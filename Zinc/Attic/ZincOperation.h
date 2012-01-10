//
//  ZincOperation.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/2/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZincClient;

@interface ZincOperation : NSOperation

- (id) initWithClient:(ZincClient*)client;

@property (nonatomic, readonly, assign) ZincClient* client;
@property (nonatomic, readonly, retain) NSError* error;

- (NSString*) descriptor;

- (double) progress;
           
@end
