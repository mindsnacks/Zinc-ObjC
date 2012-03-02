//
//  ImageFileViewController.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 3/1/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ImageFileViewController.h"

@interface ImageFileViewController ()
@property (nonatomic, retain) UIImage* image;
@end

@implementation ImageFileViewController

@synthesize imageView = _imageView;
@synthesize image = _image;

- (id)initWithImage:(UIImage*)image
{
    self = [super initWithNibName:@"ImageFileViewController" bundle:nil];
    if (self) {
        _image = [image retain];
    }
    return self;
}

- (void)dealloc
{
    [_image release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageView.image = self.image;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
