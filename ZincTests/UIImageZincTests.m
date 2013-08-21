//
//  UIImageZincTests.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/13/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "UIImageZincTests.h"
#import "UIImage+Zinc.h"
#import "UIImage+ZincHelpers.h"

@implementation UIImageZincTests

- (void) test2xPathFrom1xPath
{
    NSString* p1 = @"image.png";
    NSString* p2 = [UIImage zinc2xPathForImagePath:p1];
    STAssertTrue([p2 isEqualToString:@"image@2x.png"], @"path wrong: %@", p2);
}

- (void) test2xPathFrom2xPath
{
    NSString* p1 = @"image@2x.png";
    NSString* p2 = [UIImage zinc2xPathForImagePath:p1];
    STAssertTrue([p2 isEqualToString:@"image@2x.png"], @"path wrong");
}

- (void) test1xPathFrom2xPath
{
    NSString* p1 = @"image@2x.png";
    NSString* p2 = [UIImage zinc1xPathForImagePath:p1];
    STAssertTrue([p2 isEqualToString:@"image.png"], @"path wrong: %@", p2);
}

- (void) test1xPathFrom1xPath
{
    NSString* p1 = @"image.png";
    NSString* p2 = [UIImage zinc1xPathForImagePath:p1];
    STAssertTrue([p2 isEqualToString:@"image.png"], @"path wrong");
}


@end
