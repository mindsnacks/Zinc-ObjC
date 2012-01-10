//
//  ZincCatalogUpdateTask.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincCatalogUpdateTask.h"
#import "ZincSource.h"
#import "ZincCatalogUpdateOperation.h"
#import "ZincClient+Private.h"

@interface ZincCatalogUpdateTask ()
@property (nonatomic, retain, readwrite) ZincSource* source;
@end

@implementation ZincCatalogUpdateTask

@synthesize source = _source;

- (id) initWithClient:(ZincClient*)client source:(ZincSource*)source
{
    self = [super init];
    if (self) {
        self.source = source;
    }
    return self;
}

- (void)dealloc 
{
    self.source = nil;
    [super dealloc];
}

- (NSString*) key
{
    return [NSString stringWithFormat:@"CatalogUpdate:%@", [self.source.url absoluteString]];
}

- (NSOperation*) operation
{
    ZincCatalogUpdateOperation* op = [[[ZincCatalogUpdateOperation alloc] initWithTask:self source:self.source] autorelease];
    return op;
}

@end
