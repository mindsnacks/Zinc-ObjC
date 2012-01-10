//
//  ZincAtomicFileWriteOperation.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincAtomicFileWriteOperation.h"
#import "NSFileManager+Zinc.h"
#import "NSData+Zinc.h"

@interface ZincAtomicFileWriteOperation ()
@property (readwrite, retain) NSError* error;
@end

@implementation ZincAtomicFileWriteOperation

@synthesize data = _data;
@synthesize path = _path;
@synthesize error = _error;

- (id)initWithData:(NSData*)data path:(NSString*)path
{
    self = [super init];
    if (self) {
        self.data = data;
        self.path = path;
    }
    return self;
}

- (void)dealloc
{
    self.path = nil;
    self.data = nil;
    self.error = nil;
    [super dealloc];
}

- (void) main
{
    NSError* error = nil;
    
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    
    NSString* dir = [self.path stringByDeletingLastPathComponent];
    if (![fm zinc_createDirectoryIfNeededAtPath:dir error:&error]) {
        self.error = error;
        return;
    }
    
    if (![self.data zinc_writeToFile:self.path atomically:YES skipBackup:YES error:&error]) {
        self.error = error;
        return;
    }
}

@end
