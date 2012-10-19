//
//  ZincArchiveExtractTask.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/17/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincArchiveExtractOperation.h"
#import "ZincRepo+Private.h"
#import "NSFileManager+ZincTar.h"
#import "NSFileManager+Zinc.h"
#import "ZincUtils.h"


@interface ZincArchiveExtractOperation ()
@property (nonatomic, assign, readwrite) ZincRepo* repo;
@property (nonatomic, retain, readwrite) NSString* archivePath;
@property (nonatomic, retain, readwrite) NSError* error;
@end

@implementation ZincArchiveExtractOperation

@synthesize repo = _repo;
@synthesize archivePath = _archivePath;
@synthesize error = _error;

- (id) initWithZincRepo:(ZincRepo*)repo archivePath:(NSString*)archivePath;                
{
    self = [super init];
    if (self) {
        self.repo = repo;
        self.archivePath = archivePath;
    }
    return self;
}

- (void)dealloc 
{
    [_archivePath release];
    [_error release];
    [super dealloc];
}

- (void) main
{
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];

    NSString* untarDir = [ZincGetUniqueTemporaryDirectory() stringByAppendingPathComponent:
                          [[self.archivePath lastPathComponent] stringByDeletingPathExtension]];
    
    dispatch_block_t cleanup = ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [fm removeItemAtPath:untarDir error:NULL];
        });
    };

    if (![fm zinc_createFilesAndDirectoriesAtPath:untarDir withTarPath:self.archivePath error:&error]) {
        self.error = error;
        cleanup();
        return;
    }
    
    NSDirectoryEnumerator* dirEnum = [fm enumeratorAtPath:untarDir];
    for (NSString *thePath in dirEnum) {
        
        NSString* filename = thePath;
        if ([[thePath pathExtension] isEqualToString:@"gz"]) {
            filename = [filename stringByDeletingPathExtension];
        }
        
        NSString* targetPath = [self.repo pathForFileWithSHA:filename];
        
        if ([fm fileExistsAtPath:targetPath]) {
            continue;
        }
        
        // uncompress all gz files
        if ([[thePath pathExtension] isEqualToString:@"gz"]) {
            
            NSString* compressedPath = [untarDir stringByAppendingPathComponent:thePath];
            NSString* uncompressedPath = [compressedPath stringByDeletingPathExtension];
            
            if (![fm zinc_gzipInflate:compressedPath destination:uncompressedPath error:&error]) {
                self.error = error;
                cleanup();
                return;
            }
        }
        
        NSString* fullPath = [untarDir stringByAppendingPathComponent:filename];
        
        NSString* expectedSHA = filename;
        NSString* actualSHA = [fm zinc_sha1ForPath:fullPath];
        if (![actualSHA isEqualToString:expectedSHA]) {
            
            NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                  expectedSHA, @"expectedSHA",
                                  actualSHA, @"actualSHA",
                                  self.archivePath, @"archivePath",
                                  nil];
            error = ZincErrorWithInfo(ZINC_ERR_SHA_MISMATCH, info);
            cleanup();
            return;

        } else {
        
            if (![fm moveItemAtPath:fullPath toPath:targetPath error:&error]) {
                self.error = error;
                cleanup();
                return;
            }
            
            ZincAddSkipBackupAttributeToFileWithPath(targetPath);
        }
    }
    
    cleanup();
}

@end
