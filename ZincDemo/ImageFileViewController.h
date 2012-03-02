//
//  ImageFileViewController.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 3/1/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageFileViewController : UIViewController

- (id)initWithImage:(UIImage*)image;

@property (nonatomic, retain) IBOutlet UIImageView* imageView;

@end
