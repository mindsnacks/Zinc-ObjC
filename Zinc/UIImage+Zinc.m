//
//  UIImage+Zinc.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/13/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "UIImage+Zinc.h"
#import "ZincBundle.h"

@implementation UIImage (Zinc)

static NSCache* _imageCache;

+ (NSCache*) zincImageCache
{
    if (_imageCache == nil) {
        @synchronized(@"ZincImageCache") {
            if (_imageCache == nil) {
                _imageCache = [[NSCache alloc] init];
                _imageCache.countLimit = 10; // TODO: fix arbitrary number
            }
        }
    }
    return _imageCache;
}

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

+ (UIImage *)imageNamed:(NSString *)name inBundle:(id)bundle
{
    if (bundle == [NSBundle mainBundle]) {
        return [self imageNamed:name];
    }
    
    UIImage* image = nil;
    
    image = [_imageCache objectForKey:name];
    if (image != nil) {
        return image;
    }

    BOOL isRetina = ([UIScreen mainScreen].scale == 2.0);
    
    if (isRetina) {
        NSString* retinaName = [[self class] zinc2xPathForImagePath:name];
        NSString* retinaPath = [bundle pathForResource:[retinaName stringByDeletingPathExtension]
                                                ofType:[retinaName pathExtension]];
        image = [UIImage imageWithContentsOfFile:retinaPath];
    }
    
    if (image == nil) { 
        NSString* regularName = [[self class] zinc1xPathForImagePath:name];
        NSString* regularPath = [bundle pathForResource:[regularName stringByDeletingPathExtension]
                                                 ofType:[regularName pathExtension]];
        image = [UIImage imageWithContentsOfFile:regularPath];
    }
    
    if (image != nil) {
        [_imageCache setObject:image forKey:name];
    }
    
    return image;
}

//+ (UIImage *)imageNamed:(NSString *)name inZincBundle:(ZincBundle*)bundle
//{
//    UIImage* image = nil;
//    
//    image = [_imageCache objectForKey:name];
//    if (image != nil) {
//        return image;
//    }
//    
//    BOOL isRetina = ([UIScreen mainScreen].scale == 2.0);
//    
//    if (isRetina) {
//        NSString* retinaName = [[self class] zinc2xPathForImagePath:name];
//        NSString* retinaPath = [bundle pathForResource:retinaName];
//        image = [UIImage imageWithContentsOfFile:retinaPath];
//    }
//    
//    if (image == nil) { 
//        NSString* regularName = [[self class] zinc1xPathForImagePath:name];
//        [
//        image = [UIImage imageWithContentsOfFile:regularPath];
//    }
//    
//    if (image != nil) {
//        [_imageCache setObject:image forKey:name];
//    }
//    
//    return image;
//}


@end
