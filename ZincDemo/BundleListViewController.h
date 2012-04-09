//
//  BundleListViewController.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/31/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZincRepo;

@interface BundleListViewController : UITableViewController

- (id) initWithRepo:(ZincRepo *)repo;
@property (nonatomic, retain, readonly) ZincRepo* repo;

- (void)bundleWithId:(NSString *)bundleId didDownloadToProgress:(float)progress;

@end
