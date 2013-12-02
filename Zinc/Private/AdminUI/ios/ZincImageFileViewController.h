//
//  ZincImageFileViewController.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/27/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZincImageFileViewController : UIViewController

- (id)initWitImagePath:(NSString *)imagePath;

+ (NSArray *)supportedExtensions;

@end
