//
//  ZCBundle.m
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZCBundle.h"
#import "ZCBundle+Private.h"

@interface ZCBundle ()
@property (nonatomic, retain, readwrite) NSURL* url;
@end

@implementation ZCBundle

@synthesize url = _url;
@synthesize version = _version;
@synthesize fileManager = _fileManager;

- (id) initWithURL:(NSURL*)url
{
    self = [super init];
    if (self) {
        self.url = url;
        self.fileManager = [[[NSFileManager alloc] init] autorelease];
    }
    return self;
}

- (id) initWithPath:(NSString*)path
{
    return [self initWithURL:[NSURL fileURLWithPath:path]];
}

- (void)dealloc 
{
    self.url = nil;
    self.fileManager = nil;
    [super dealloc];
}

- (NSArray*) availableVersions;
{
    return nil;
}


@end
