//
//  ZincBundleContentsViewController.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/26/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZincManifest;

@interface ZincBundleContentsViewController : UITableViewController

- (id)initWithManifest:(ZincManifest *)manifest rootPath:(NSString *)rootPath;

@end
