//
//  ZincGarbageCollectTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincGarbageCollectTask.h"
#import "ZincTask+Private.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincResource.h"
#import "ZincManifest.h"
#import "ZincEvent.h"
#import "ZincTaskActions.h"

@implementation ZincGarbageCollectTask

+ (NSString *)action
{
    return ZincTaskActionUpdate;
}

- (void) main
{
    //ZINC_DEBUG_LOG(@"GARBAGE COLLECT -- BEGIN");
    [self addEvent:[ZincGarbageCollectionBeginEvent event]];
    
    NSError* error = nil;

    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    NSDirectoryEnumerator* dirEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:[self.repo filesPath]]
                              includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsRegularFileKey, NSURLLinkCountKey, NSURLIsSymbolicLinkKey, nil]
                                                 options:0 
                                            errorHandler:^(NSURL* url, NSError* error){
                                                
                                                return YES;
                                            }];
    for (NSURL *theURL in dirEnum) {
        
        NSNumber *isRegularFile;
        if (![theURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
            continue;
        }
        
        if ([isRegularFile boolValue]) {
            
            NSNumber *linkCount;
            if (![theURL getResourceValue:&linkCount forKey:NSURLLinkCountKey error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                continue;
            }
            
            if ([linkCount integerValue] < 2) {
                [fm removeItemAtURL:theURL error:NULL];
            }
            
        } else {
            
            NSNumber *isSymlink;
            if (![theURL getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
                continue;
            }
            
            if ([isSymlink boolValue]) {
                NSURL* resolvedURL = [theURL URLByResolvingSymlinksInPath];
                if ([resolvedURL isEqual:theURL]) {
                    // if it's the same, the symlink is invalid
                    [fm removeItemAtURL:theURL error:NULL];
                }
            }
        }
    }
    
    [self addEvent:[ZincGarbageCollectionCompleteEvent event]];
    //ZINC_DEBUG_LOG(@"GARBAGE COLLECT -- END");
}

@end
