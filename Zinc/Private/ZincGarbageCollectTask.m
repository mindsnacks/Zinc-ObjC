//
//  ZincGarbageCollectTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincGarbageCollectTask.h"

#import "ZincInternals.h"
#import "ZincTask+Private.h"
#import "ZincRepo+Private.h"

@implementation ZincGarbageCollectTask

+ (NSString *)action
{
    return @"GarbageCollect";
}

- (void) doMaintenance
{
    NSLog(@"GarbageCollect started");

    NSError* error = nil;
    NSFileManager* fm = [[NSFileManager alloc] init];
    NSDirectoryEnumerator* filesEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:[self.repo filesPath]]
                                includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLLinkCountKey]
                                                   options:0
                                              errorHandler:^(NSURL* url, NSError* e){
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

    NSLog(@"GarbageCollect done");
}

@end
