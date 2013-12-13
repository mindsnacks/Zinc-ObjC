//
//  ZincFileUpdateTask2.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincObjectDownloadTask.h"

#import "ZincInternals.h"
#import "ZincTask+Private.h"
#import "ZincDownloadTask+Private.h"
#import "ZincRepo+Private.h"
#import "ZincSHA.h"
#import "ZincEventHelpers.h"
#import "ZincURLSession.h"

@interface ZincObjectDownloadTask ()
@property (readwrite) NSInteger bytesRead;
@property (readwrite) NSInteger totalBytesToRead;
@end


@implementation ZincObjectDownloadTask

- (NSString*) sha
{
    return [self.resource zincObjectSHA];
}

- (void) main
{
    NSError* error = nil;
    BOOL gz = NO;
    NSFileManager* fm = [[NSFileManager alloc] init];

    // don't need to donwload if the file already exists
    if ([self.repo hasFileWithSHA:self.sha])
    {
        self.finishedSuccessfully = YES;
        return;
    }

    NSArray* formats = (NSArray*)[self input];
    
    if ([formats containsObject:ZincFileFormatGZ]) {
        gz = YES;
    }
        
    NSString* ext = nil;
    if (gz) {
        ext = @"gz";
    }
    
    NSString* catalogID = [self.resource zincCatalogID];
    
    NSArray* sources = [self.repo sourcesForCatalogID:catalogID];
    if (sources == nil || [sources count] == 0) {
        NSDictionary* info = @{@"catalogID": catalogID};
        error = ZincErrorWithInfo(ZINC_ERR_NO_SOURCES_FOR_CATALOG, info);
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
        return;
    }
    
    for (NSURL* source in sources) {
        
        NSString* uncompressedPath = [[self.repo downloadsPath] stringByAppendingPathComponent:self.sha];
        NSString* compressedPath = [uncompressedPath stringByAppendingPathExtension:@"gz"];
        
        if ([fm fileExistsAtPath:uncompressedPath]) {
            if (![fm removeItemAtPath:uncompressedPath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
                continue;
            }
        }
        
        if ([fm fileExistsAtPath:compressedPath]) {
            if (![fm removeItemAtPath:compressedPath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
                continue;
            }
        }
        
        NSString* downloadPath = uncompressedPath;
        if (gz) {
            downloadPath = compressedPath;
        }
        
        NSURLRequest* request = [source urlRequestForFileWithSHA:self.sha extension:ext];
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        [self queueOperationForRequest:request downloadPath:downloadPath context:nil completion:^{
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        dispatch_release(sem);

        //[self.URLSessionTask waitUntilFinished];
        if (self.isCancelled) return;

        NSDictionary* eventAttrs = [ZincEventHelpers attributesForRequest:self.URLSessionTask.originalRequest andResponse:self.URLSessionTask.response];
        
        if (self.URLSessionTask.error != nil) {
            [self addEvent:[ZincErrorEvent eventWithError:self.URLSessionTask.error source:ZINC_EVENT_SRC() attributes: eventAttrs]];
            continue;
        } else {
            [self addEvent:[ZincDownloadCompleteEvent downloadCompleteEventForURL:request.URL size:self.bytesRead]];
        }
        
        NSString* targetPath = [self.repo pathForFileWithSHA:self.sha];
        
        if (gz) {
            NSData* compressed = [[NSData alloc] initWithContentsOfFile:downloadPath];
            NSData* uncompressed = [compressed zinc_gzipInflate];
            if (![uncompressed writeToFile:uncompressedPath options:0 error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC() attributes:eventAttrs]];
                // don't return/continue! still need to clean up
            }
        } 
        
        NSString* actualSHA = ZincSHA1HashFromPath(uncompressedPath, 0, &error);
        if (actualSHA == nil) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
            continue;
        }
        
        if (![actualSHA isEqualToString:self.sha]) {
            
            NSDictionary* info = @{@"expectedSHA": self.sha,
                    @"actualSHA": actualSHA,
                    @"source": source};
            error = ZincErrorWithInfo(ZINC_ERR_SHA_MISMATCH, info);
            [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
            continue;
            
        } else {
            
            NSString* targetDir = [targetPath stringByDeletingLastPathComponent];
            if (![fm zinc_createDirectoryIfNeededAtPath:targetDir error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
                continue;
            }

            if (![fm zinc_moveItemAtPath:uncompressedPath toPath:targetPath error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
                continue;
            }

            ZincAddSkipBackupAttributeToFileWithPath(targetPath);
            self.finishedSuccessfully = YES;
        }
        
        if (compressedPath != nil) {
            [fm removeItemAtPath:compressedPath error:NULL];
        }
        
        if (uncompressedPath != nil) {
            [fm removeItemAtPath:uncompressedPath error:NULL];
        }
        
        self.finishedSuccessfully = YES;
        
        break; // make sure to break out of the loop when we finish successfully 
    }
}

@end
