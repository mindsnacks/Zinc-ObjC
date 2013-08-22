//
//  ZincRepoAgent+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/30/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincAgent.h"

#define kZincAgentDefaultAutoRefreshInterval (120)

@class ZincRepo;
@class KSReachability;

@interface ZincAgent (Private)

- (id)initWithRepo:(ZincRepo *)repo reachability:(KSReachability*)reachability;

@property (nonatomic, strong, readwrite) ZincRepo *repo;
@property (nonatomic, strong, readwrite) KSReachability *reachability;


@end