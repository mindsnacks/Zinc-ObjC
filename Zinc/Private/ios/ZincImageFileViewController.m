//
//  ZincImageFileViewController.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/27/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincImageFileViewController.h"

@interface ZincImageFileViewController ()
@property (nonatomic, strong) NSString *imagePath;
@end

@implementation ZincImageFileViewController

- (id)initWitImagePath:(NSString *)imagePath
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.imagePath = imagePath;
        self.title = [imagePath lastPathComponent];
    }
    return self;
}

- (void)loadView
{
    [super loadView];

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];

    imageView.image = [UIImage imageWithContentsOfFile:self.imagePath];
}

+ (NSArray *)supportedExtensions
{
    return @[@"png", @"jpg"];
}


@end
