//
//  ViewController.h
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZincRepo;

@interface ViewController : UIViewController


@property (nonatomic, retain) ZincRepo* repo;

- (IBAction)beginTracking:(id)sender;
- (IBAction)stopTracking:(id)sender;

@end
