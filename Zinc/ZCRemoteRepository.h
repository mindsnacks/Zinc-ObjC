//
//  ZCRepo.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/16/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZCRemoteRepository : NSObject

+ (ZCRemoteRepository*) remoteRepositoryWitURL:(NSURL*)url;
@property (nonatomic, retain, readonly) NSURL* url;

- (NSURLRequest*) urlRequestForIndex;

@end
