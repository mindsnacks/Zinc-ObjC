//
//  UIImage+Zinc.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/13/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "UIImage+Zinc.h"
#import "ZincBundle.h"
#import "ZincUtils.h"
#import "UIImage+ZincHelpers.h"

@implementation UIImage (Zinc)

+ (UIImage *)zinc_imageNamed:(NSString *)name inBundle:(id)bundle
{
    if (bundle == [NSBundle mainBundle]) {
        return [self imageNamed:name];
    }
    
    UIImage* image = nil;
    NSMutableArray* imageNames = [NSMutableArray arrayWithObject:name];
    
    BOOL isRetina = ([UIScreen mainScreen].scale == 2.0);
    if (isRetina) {
        NSString* retinaName = [[self class] zinc2xPathForImagePath:name];
        [imageNames insertObject:retinaName atIndex:0];
    }
    
    NSString* bundlePath = [bundle bundlePath];
    NSString* relParentDir = nil;
    NSArray* searchDirs = @[ZincGetApplicationDocumentsDirectory(), ZincGetApplicationCacheDirectory()];
    
    for (NSString* pathPrefix in searchDirs) {
        if ([bundlePath hasPrefix:pathPrefix]) {
            relParentDir = [bundlePath stringByReplacingOccurrencesOfString:pathPrefix withString:
                            [NSString stringWithFormat:@"../%@", [pathPrefix lastPathComponent]]];
            break;
        }
    }
    
    if (relParentDir != nil) {
        for (NSString* imageName in imageNames) {
            NSString* imagePath = [relParentDir stringByAppendingPathComponent:imageName];
            image = [UIImage imageNamed:imagePath];
            if (imageName != nil) break;
        }
    }
    
    // if the image is still nil, try to load without the cache
    if (image == nil) {
        for (NSString* imageName in imageNames) {
            image = [UIImage imageWithContentsOfFile:
                     [bundlePath stringByAppendingPathComponent:imageName]];
            if (image != nil)
                break;
        }
    }
    
    return image;
}

@end
