//
//  ViewController.m
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ViewController.h"
#import "ZincRepo.h"

@implementation ViewController

@synthesize repo = _repo;
@synthesize bundle = _bundle;

- (void)dealloc {
    self.repo = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)beginTracking:(id)sender
{
    [self.repo beginTrackingBundleWithId:@"com.mindsnacks.french.AdvancedNumbers" distribution:@"master"];
}

- (IBAction)stopTracking:(id)sender
{
    [self.repo stopTrackingBundleWithId:@"com.mindsnacks.french.AdvancedNumbers"];
}

- (IBAction)getBundle:(id)sender
{
    self.bundle = [self.repo bundleWithId:@"com.mindsnacks.french.AdvancedNumbers"];
    NSAssert(self.bundle, @"ow");
}

- (IBAction)releaseBundle:(id)sender
{
    self.bundle = nil;   
}

 


@end
