//
//  DownloadsVC.h
//  MindSnacks
//
//  Created by Andy Mroczkowski on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZincRepo;

@interface ZincActivityViewController : UITableViewController

- (id) initWithRepo:(ZincRepo *)repo;

@end
