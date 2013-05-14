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

@implementation UIImage (Zinc)

+ (NSString*) zinc2xPathForImagePath:(NSString*)path
{
    NSString* file = [path lastPathComponent];
    NSString* fileName = [file stringByDeletingPathExtension];
    
    if ([fileName hasSuffix:@"@2x"]) {
        return path;
    } 
    
    NSString* dir = [path stringByDeletingLastPathComponent];
    NSString* ext = [path pathExtension];
    
    fileName = [fileName stringByAppendingString:@"@2x"];
    file = [fileName stringByAppendingPathExtension:ext];
    path = [dir stringByAppendingPathComponent:file];
    
    return path;
}

+ (NSString*) zinc1xPathForImagePath:(NSString*)path
{
    NSString* file = [path lastPathComponent];
    NSString* fileName = [file stringByDeletingPathExtension];
    
    if (![fileName hasSuffix:@"@2x"]) {
        return path;
    } 
    
    NSString* dir = [path stringByDeletingLastPathComponent];
    NSString* ext = [path pathExtension];
    
    fileName = [fileName substringToIndex:[fileName length] - [@"@2x" length]];
    file = [fileName stringByAppendingPathExtension:ext];
    path = [dir stringByAppendingPathComponent:file];
    
    return path;
}

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
        image = [UIImage imageWithContentsOfFile:
                 [bundlePath stringByAppendingPathComponent:name]];
    }
    
    return image;
}

@end
