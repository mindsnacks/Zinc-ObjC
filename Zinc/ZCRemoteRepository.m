//
//  ZCRepo.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/16/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZCRemoteRepository.h"

@interface ZCRemoteRepository ()
@property (nonatomic, retain, readwrite) NSURL* url;
@end

@implementation ZCRemoteRepository

@synthesize url = _url;

+ (ZCRemoteRepository*) remoteRepositoryWitURL:(NSURL*)url
{
    // TODO: validate URL
    ZCRemoteRepository* remote = [[[ZCRemoteRepository alloc] init] autorelease];
    remote.url = url;
    return remote;
}

- (void)dealloc
{
    self.url = nil;
    [super dealloc];
}

- (NSURLRequest*) urlRequestForIndex
{
    NSURL* indexURL = [NSURL URLWithString:@"index.json" relativeToURL:self.url];
    NSMutableURLRequest* req = [[[NSMutableURLRequest alloc] initWithURL:indexURL] autorelease];
    [req setHTTPMethod:@"GET"];
    return req;
}




@end
