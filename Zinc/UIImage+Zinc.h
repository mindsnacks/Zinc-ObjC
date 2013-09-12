//
//  UIImage+Zinc.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/13/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 `UIImage (Zinc)` - extensions for `UIImage`.

 This class is part of the *Zinc Public API*.
 */
@interface UIImage (Zinc)

/**
 Replacement for `[UIImage imageNamed:]` that will look in the specified bundle.
 
 @param name The image name
 @param bundle A bundle, which can be an NSBundle or a ZincBundle
 */
+ (UIImage *)zinc_imageNamed:(NSString *)name inBundle:(id)bundle;

@end