//
//  ZincCatalogUpdateTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincCatalogUpdateTask.h"
#import "ZincTask+Private.h"
#import "ZincCatalog.h"
#import "ZincResource.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincEvent.h"
#import "NSData+Zinc.h"
#import "ZincTaskActions.h"
@implementation ZincCatalogUpdateTask

+ (NSString *)action
{
    return ZincTaskActionUpdate;
}

- (id) initWithRepo:(ZincRepo*)repo resourceDescriptor:(NSURL*)resource input:(id)input
{
    self = [super initWithRepo:repo resourceDescriptor:resource input:input];
    if (self) {
        self.title = NSLocalizedString(@"Updating Catalog", @"ZincCatalogUpdateTask");
    }
    return self;
}

- (void)dealloc 
{
    [super dealloc];
}

- (ZincCatalog*) catalog
{
    return self.input;
}

- (void) main
{
    NSError* error = nil;
    
    NSData* data = [self.catalog jsonRepresentation:&error];
    if (data == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC_METHOD()]];
        return;
    }
    
    NSString* path = [self.repo pathForCatalogIndex:self.catalog];
    if (![data zinc_writeToFile:path atomically:YES createDirectories:YES skipBackup:YES error:&error]) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC_METHOD()]];
        return;
    }
    
    [self.repo registerCatalog:self.catalog];
    
    self.finishedSuccessfully = YES;
}
@end
