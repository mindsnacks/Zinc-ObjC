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

@property (nonatomic, readonly, retain) ZincRepo* repo;
@property (nonatomic, readonly, retain) NSPredicate* taskPredicate;

#pragma mark Convenience Constructors

+ (ZincRepoMonitor*) repoMonitorForBundleCloneTasksInRepo:(ZincRepo*)repo;

@end


