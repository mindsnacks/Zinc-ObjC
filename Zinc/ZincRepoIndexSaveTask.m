//
//  ZincRepoIndexWriteTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepoIndexSaveTask.h"
#import "ZincTask+Private.h"
#import "ZincResource.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincRepoIndex.h"
#import "ZincEvent.h"
#import "NSData+Zinc.h"
#import "ZincTaskActions.h"


@implementation ZincRepoIndexSaveTask


+ (NSString *)action
{
    return ZincTaskActionUpdate;
}


- (void)dealloc 
{
    [super dealloc];
}


- (void) taskMain
{    
    NSError* error = nil;
    
    NSData* jsonData = [self.repo.index jsonRepresentation:&error];
    if (jsonData == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
        return;
    }
    
    if (![jsonData zinc_writeToFile:[[self.repo indexURL] path] atomically:YES createDirectories:NO skipBackup:YES error:&error]) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
        return;
    }

    self.finishedSuccessfully = YES;
}


@end
