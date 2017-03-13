//
//  ZincCatalogUpdateTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincCatalogUpdateTask.h"

#import "ZincInternals.h"
#import "ZincTask+Private.h"
#import "ZincRepo+Private.h"
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

- (ZincCatalog*) catalog
{
    return self.input;
}

- (void) main
{
    NSError* error = nil;
    
    NSData* data = [self.catalog jsonRepresentation:&error];
    if (data == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
        return;
    }
    
    NSString* path = [self.repo pathForCatalogIndex:self.catalog];
    if ([data zinc_writeToFile:path atomically:YES createDirectories:YES skipBackup:YES error:&error]) {
        [self addEvent:[ZincCatalogUpdatedEvent catalogUpdatedEventWithURL:[self.repo indexURL] source:ZINC_EVENT_SRC()]];
        [self.repo registerCatalog:self.catalog];
        self.finishedSuccessfully = YES;
    } else {
        [self addEvent:[ZincErrorEvent eventWithError:error source:ZINC_EVENT_SRC()]];
    }
}
@end
