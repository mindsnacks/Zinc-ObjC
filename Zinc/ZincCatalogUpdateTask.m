//
//  ZincCatalogUpdateTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincCatalogUpdateTask.h"
#import "ZincCatalog.h"
#import "ZincResourceDescriptor.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincEvent.h"
#import "NSData+Zinc.h"

@interface ZincCatalogUpdateTask ()
@property (nonatomic, retain, readwrite) ZincCatalog* catalog;
@end

@implementation ZincCatalogUpdateTask

@synthesize catalog = _catalog;

- (id) initWithRepo:(ZincRepo *)repo catalog:(ZincCatalog*)catalog
{
    ZincCatalogDescriptor* desc = [ZincCatalogDescriptor catalogDescriptorForId:catalog.identifier];
    self = [super initWithRepo:repo resourceDescriptor:desc];
    if (self) {
        self.catalog = catalog;
        self.title = @"Updating Catalog"; // TODO: localization
    }
    return self;
}

- (void)dealloc 
{
    self.catalog = nil;
    [super dealloc];
}

- (void) main
{
    NSError* error = nil;
    
    NSData* data = [[self.catalog jsonRepresentation:&error] dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    NSString* path = [self.repo pathForCatalogIndex:self.catalog];
    if (![data zinc_writeToFile:path atomically:YES createDirectories:YES skipBackup:YES error:&error]) {
        [self addEvent:[ZincErrorEvent eventWithError:error source:self]];
        return;
    }
    
    self.finishedSuccessfully = YES;
}
@end
