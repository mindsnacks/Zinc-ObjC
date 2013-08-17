//
//  ZincRepoAgent+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/30/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincRepoAgent.h"

@class ZincRepo;

@interface ZincRepoAgent (Private)

- (id)initWithRepo:(ZincRepo *)repo;

@property (nonatomic, weak, readonly) ZincRepo *repo;

@end