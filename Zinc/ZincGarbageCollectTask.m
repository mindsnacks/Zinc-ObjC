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

@implementation ZincGarbageCollectTask

+ (NSString *)action
{
    return @"GarbageCollect";
}

- (void) doMaintenance
{
    NSError* error = nil;
    NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
    NSDirectoryEnumerator* filesEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:[self.repo filesPath]]
                                includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsRegularFileKey, NSURLLinkCountKey, nil]
                                                   options:0
                                              errorHandler:^(NSURL* url, NSError* error){
                                                  return YES;
                                              }];
    for (NSURL *theURL in filesEnum) {
        NSNumber *isRegularFile;
        if (![theURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:&error]) {
            [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
            continue;
        }
        if ([isRegularFile boolValue]) {
            NSNumber *linkCount;
            if (![theURL getResourceValue:&linkCount forKey:NSURLLinkCountKey error:&error]) {
                [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
                continue;
            }
            if ([linkCount integerValue] < 2) {
                [fm removeItemAtURL:theURL error:NULL];
            }
        }
    }
}

@end
