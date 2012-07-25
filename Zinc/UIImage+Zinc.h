//
//  UIImage+Zinc.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/13/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Zinc)

/* bundle can be an NSBundle or ZincBundle */
+ (UIImage *)zinc_imageNamed:(NSString *)name inBundle:(id)bundle;

#pragma mark Private

+ (NSString*) zinc1xPathForImagePath:(NSString*)path;
+ (NSString*) zinc2xPathForImagePath:(NSString*)path;

@end