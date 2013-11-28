//
//  ZincBundleManagementViewController.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/7/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZincRepo;

@interface ZincBundleManagementViewController : UINavigationController

- (id)initWithRepo:(ZincRepo *)repo;

@end
