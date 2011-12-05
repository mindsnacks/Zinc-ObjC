//
//  ZCBundle.m
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZCBundle.h"
#import "ZCBundle+Private.h"
#import "NSFileManager+Zinc.h"

#define ZINC_FORMAT_FILE @"zinc_format.txt"

static NSMutableDictionary * _ZCBundle_sharedURLMap;

@interface ZCBundle ()
@property (nonatomic, retain, readwrite) NSURL* url;
@end


@implementation ZCBundle

@synthesize url = _url;
@synthesize version = _version;
@synthesize fileManager = _fileManager;

+ (void) initialize
{
	if ( self == [ZCBundle class] ) {
		_ZCBundle_sharedURLMap = [[NSMutableDictionary alloc] init];
	}
}

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

+ (ZincFormat) readZincFormatFromURL:(NSURL*)url error:(NSError**)outError
{
    NSFileManager* fm = [NSFileManager zinc_newFileManager];
    NSString* path = [[url path] stringByAppendingPathComponent:ZINC_FORMAT_FILE];
    if (![fm fileExistsAtPath:path]) {
        // file doesn't exist error
        return ZincFormatInvalid;
    }
    
    NSString* string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:outError];
    if (string == nil) {
        return ZincFormatInvalid;
    }
    
    if ([string integerValue] == 0) {
        return ZincFormatInvalid;
    }
    
    return [string integerValue];;
}

+ (ZCBundle*) bundleWithURL:(NSURL*)url error:(NSError**)outError
{
    
}

+ (ZCBundle*) bundleWithPath:(NSString*)path error:(NSError**)outError
{
    
}

- (void)dealloc 
{
    // -- remove from sharedMap
	@synchronized(_ZCBundle_sharedURLMap) {
		[_ZCBundle_sharedURLMap removeObjectForKey:[self.url absoluteString]];
	}
    
    self.url = nil;
    self.fileManager = nil;
    [super dealloc];
}

- (NSArray*) availableVersions;
{
    return nil;
}


@end
