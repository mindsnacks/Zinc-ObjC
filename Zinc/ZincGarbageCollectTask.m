//
//  ZincGarbageCollectTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincGarbageCollectTask.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincBundleDescriptor.h"
#import "ZincManifest.h"

@implementation ZincGarbageCollectTask

- (void) main
{
    ZINC_DEBUG_LOG(@"GARBAGE COLLECT -- BEGIN");
    
    NSError* error = nil;

    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    NSDirectoryEnumerator* dirEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:[self.repo filesPath]]
                              includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsRegularFileKey, NSURLLinkCountKey, nil]
                                                 options:0 
                                            errorHandler:^(NSURL* url, NSError* error){
                                                
                                                return YES;
                                            }];
    for (NSURL *theURL in dirEnum) {
        
        NSNumber *isRegularFile;
        if (![theURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:&error]) {
            // TODO: log error
            continue;
        }
        
        if ([isRegularFile boolValue]) {
            
            NSNumber *linkCount;
            if (![theURL getResourceValue:&linkCount forKey:NSURLLinkCountKey error:&error]) {
                // TODO: log error
                continue;
            }
            
            if ([linkCount integerValue] < 2) {
                NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
                [fm removeItemAtURL:theURL error:NULL];
            }
        }
    }
    
    ZINC_DEBUG_LOG(@"GARBAGE COLLECT -- END");
}

@end
