//
//  BundleDetailViewController.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 2/1/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZincBundle;
@class ZincRepo;

@interface BundleDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (id) initWithBundle:(ZincBundle*)bundle repo:(ZincRepo*)repo;
@property (nonatomic, retain, readonly) ZincBundle* bundle;
@property (nonatomic, retain, readonly) ZincRepo* repo;

@property (nonatomic, retain) IBOutlet UITableView* tableView;

@end
