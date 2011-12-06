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
#import "ZCFileSystem.h"


static const char* queue_name_for_url(NSURL* url) {
    return [[kZincPackageName stringByAppendingFormat:@".bundle#%@",
             [url absoluteString]] cStringUsingEncoding:NSUTF8StringEncoding];
}

static NSMutableDictionary * _ZCBundle_sharedURLMap;


@interface ZCBundle ()
@property (nonatomic, assign) dispatch_queue_t queue;
@end


@implementation ZCBundle

@synthesize version = _version;
@synthesize fileSystem = _fileSystem;
@synthesize queue = _queue;

+ (void) initialize
{
	if ( self == [ZCBundle class] ) {
		_ZCBundle_sharedURLMap = [[NSMutableDictionary alloc] init];
	}
}

- (id) initWithFileSystem:(ZCFileSystem*)fileSystem
{
    self = [super init];
    if (self) {
        //self.queue = dispatch_queue_create(queue_name_for_url(self.url), NULL);
        self.fileSystem = fileSystem;
    }
    return self;
}

- (void) dealloc 
{
    // -- remove from sharedMap
	@synchronized(_ZCBundle_sharedURLMap) {
		[_ZCBundle_sharedURLMap removeObjectForKey:[[self url] absoluteString]];
	}
    
    self.fileSystem = nil;
    [super dealloc];
}

+ (ZCBundle*) bundleWithURL:(NSURL*)url error:(NSError**)outError
{
    ZCFileSystem* zcfs = [ZCFileSystem fileSystemForWithURL:url error:outError];
    if (zcfs == nil) {
        return nil;
    }
    
    ZCBundle* bundle = [[[ZCBundle alloc] initWithFileSystem:zcfs] autorelease];
    return bundle;
}

+ (ZCBundle*) bundleWithURL:(NSURL*)url version:(ZincVersionMajor)version error:(NSError**)outError
{
    ZCBundle* bundle = [self bundleWithURL:url error:outError];
    if (bundle == nil) {
        return nil;
    }

    return bundle;
}

+ (ZCBundle*) bundleWithPath:(NSString*)path error:(NSError**)outError
{
    return [self bundleWithURL:[NSURL fileURLWithPath:path] error:outError];
}

+ (ZCBundle*) bundleWithPath:(NSString*)path version:(ZincVersionMajor)version error:(NSError**)outError
{
    return [self bundleWithURL:[NSURL fileURLWithPath:path] version:version error:outError];
}


#pragma mark Accessors

- (NSArray*) availableVersions;
{
    return nil;
}

- (NSURL*) url
{
    return self.fileSystem.url;
}


#pragma <#arguments#>


@end
