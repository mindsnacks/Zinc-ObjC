//
//  ZincBundleCloneTask.m
//
//
//  Created by Andy Mroczkowski on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZincBundleCloneTask+Private.h"

#import "ZincInternals.h"
#import "ZincTask+Private.h"
#import "ZincRepo+Private.h"
#import "ZincTaskActions.h"

@implementation ZincBundleCloneTask

+ (NSString *)action
{
    return ZincTaskActionUpdate;
}

- (NSString*) bundleID
{
    return [self.resource zincBundleID];
}

- (ZincVersion) version
{
    return [self.resource zincBundleVersion];
}

- (NSString*) getTrackedFlavor
{
    return [self.repo.index trackedFlavorForBundleID:self.bundleID];
}

- (void) setUp
{
    self.fileManager = [[NSFileManager alloc] init];
    [self addEvent:[ZincBundleCloneBeginEvent bundleCloneBeginEventForBundleResource:self.resource source:ZINC_EVENT_SRC() context:self.bundleID]];
}

- (void) completeWithSuccess:(BOOL)success
{
    if (success) {
        [self.repo registerBundle:self.resource status:ZincBundleStateAvailable];
    } else {
        [self.repo registerBundle:self.resource status:ZincBundleStateNone];
    }

    [self addEvent:[ZincBundleCloneCompleteEvent bundleCloneCompleteEventForBundleResource:self.resource source:ZINC_EVENT_SRC() context:self.bundleID success:success]];
    
    self.finishedSuccessfully = success;
}

@end
