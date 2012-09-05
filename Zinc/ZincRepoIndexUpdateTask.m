//
//  ZincRepoIndexWriteTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/12/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincRepoIndexUpdateTask.h"
#import "ZincResource.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincRepoIndex.h"
#import "ZincEvent.h"
#import "NSData+Zinc.h"
#import "ZincTaskActions.h"

@implementation ZincRepoIndexUpdateTask

+ (NSString *)action
{
    return ZincTaskActionUpdate;
}

- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input
{
    self = [super initWithRepo:repo resourceDescriptor:resource input:input];
    if (self) {
        self.title = NSLocalizedString(@"Updating Index", @"ZincRepoIndexUpdateTask");
    }
    return self;
}

- (void)dealloc 
{
    [super dealloc];
}

- (void) main
{
    NSError* error = nil;
    
    NSData* jsonData = [self.repo.index jsonRepresentation:&error];
    if (jsonData == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    if (![jsonData zinc_writeToFile:[[self.repo indexURL] path] atomically:YES createDirectories:NO skipBackup:YES error:&error]) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }

    self.finishedSuccessfully = YES;
}

@end
