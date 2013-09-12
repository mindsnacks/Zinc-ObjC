//
//  AppDelegate.h
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZincRepo.h"

@class ZincAgent;

@interface AppDelegate : UIResponder <UIApplicationDelegate, ZincRepoEventListener>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ZincAgent *zincAgent;

@end
