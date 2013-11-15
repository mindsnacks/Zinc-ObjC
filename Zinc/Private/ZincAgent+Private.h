//
//  ZincRepoAgent+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/30/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincAgent.h"

@class ZincRepo;

@interface ZincAgent (Private)

- (id)initWithRepo:(ZincRepo *)repo;

@property (nonatomic, strong, readwrite) ZincRepo *repo;


@end