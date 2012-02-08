//
//  BundleDetailViewController.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 2/1/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "BundleDetailViewController.h"
#import "Zinc.h"
#import "ZincRepo+Private.h"
#import "ZincManifest.h"

@implementation BundleDetailViewController

@synthesize bundle = _bundle;
@synthesize repo = _repo;
@synthesize bundleNameLabel = _bundleNameLabel;
@synthesize bundleVersionLabel = _bundleVersionLabel;
@synthesize manifestTextView = _manifestTextView;

- (id) initWithBundle:(ZincBundle*)bundle repo:(ZincRepo*)repo
{
    self = [super initWithNibName:@"BundleDetailViewController" bundle:nil];
    if (self) {
        _bundle = [bundle retain];
        _repo = [repo retain];
    }
    return self;
}

- (void)dealloc {
    [_bundle release];
    [_repo release];
    [super dealloc];
}

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bundleNameLabel.text = self.bundle.bundleId;
    self.bundleVersionLabel.text = [NSString stringWithFormat:@"%d", self.bundle.version];
    
    self.title = [NSString stringWithFormat:@"%@-%d", [ZincBundle bundleNameFromBundleId:self.bundle.bundleId], self.bundle.version];

    [self.bundle.repo bundleWithId:self.bundle.bundleId];
    
    ZincManifest* manifest = [self.repo manifestWithBundleIdentifier:self.bundle.bundleId version:self.bundle.version error:NULL];
    
    NSString* manifestString = [[manifest dictionaryRepresentation] description];
    
    self.manifestTextView.text = manifestString;
    
    NSBundle* bundle = [self.bundle NSBundle];
    NSString* path1 = [bundle pathForResource:@"Advanced Numbers" ofType:@"js"];
    NSLog(@"path1: %@", path1);
    NSString* path2 = [bundle pathForResource:@"Advanced Numbers.js"];
    NSLog(@"path2: %@", path2);
    
    NSString* audioPath = [bundle pathForResource:@"audio/more-adv-numbers-20" ofType:@"caf"];
    NSLog(@"audioPath: %@", audioPath);
    
    NSLog(@"id %@", self.bundle.bundleId);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
