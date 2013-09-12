//
//  ZincActivityMonitor.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/8/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincActivityMonitor.h"

@class ZincRepo;

@interface ZincRepoMonitor : ZincActivityMonitor

- (id)initWithRepo:(ZincRepo*)repo taskPredicate:(NSPredicate*)taskPredicate;

@property (nonatomic, readonly, strong) ZincRepo* repo;
@property (nonatomic, readonly, strong) NSPredicate* taskPredicate;

#pragma mark Convenience Constructors

+ (ZincRepoMonitor*) repoMonitorForBundleCloneTasksInRepo:(ZincRepo*)repo;

@end


