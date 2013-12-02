//
//  ZincBundleDetailViewController.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/8/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZincRepo;

@interface ZincBundleDetailViewController : UITableViewController

- (id)initWithBundleID:(NSString *)bundleID repo:(ZincRepo *)repo;

@end
