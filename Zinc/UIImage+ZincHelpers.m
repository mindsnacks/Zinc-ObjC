//
//  UIImage+ZincHelpers.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 8/21/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "UIImage+ZincHelpers.h"

@implementation UIImage (ZincHelpers)

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

@end
