//
//  ZincAdminViewController.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/5/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZincRepo;

@interface ZincAdminViewController : UIViewController <UITabBarDelegate>


/**
 Designated initializer
 */
- (id)initWithRepo:(ZincRepo *)repo;

@property (nonatomic, strong, readonly) ZincRepo *repo;

@end
