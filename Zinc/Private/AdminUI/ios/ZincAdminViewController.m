//
//  ZincAdminViewController.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/5/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincAdminViewController.h"

#import "ZincInternals.h"
#import "ZincBundleManagementViewController.h"
#import "ZincActivityViewController.h"

@interface ZincAdminViewController ()
@property (nonatomic, strong, readwrite) ZincRepo *repo;

@property (nonatomic, strong) UIToolbar *toolBar;
@property (nonatomic, strong) UISegmentedControl *viewSelector;
@property (nonatomic, strong) ZincBundleManagementViewController *bundleManagementViewController;
@property (nonatomic, strong) ZincActivityViewController *activityViewController;

@end

#define kToolbarHeight (36)

enum kViewIndex {
    kViewIndexBundles,
    kViewIndexActivity
    };

@implementation ZincAdminViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithRepo:nil];
}

- (id)init
{
    return [self initWithRepo:nil];
}

- (id)initWithRepo:(ZincRepo *)repo
{
    NSParameterAssert(repo);

    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.repo = repo;
    }
    return self;
}

- (void)loadView
{
    [super loadView];

    self.toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, kToolbarHeight)];
    [self.view addSubview:self.toolBar];

    self.viewSelector = [[UISegmentedControl alloc] initWithItems:@[
                                                                    NSLocalizedString(@"Bundles", @"ZincAdminViewController Bundles Tab Title"),
                                                                    NSLocalizedString(@"Activity", @"ZincAdminViewController Activity Tab Title")]];
    self.viewSelector.frame = CGRectMake(20, 6, 280, 24);
    self.viewSelector.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.viewSelector.segmentedControlStyle = UISegmentedControlStyleBar;
    [self.toolBar addSubview:self.viewSelector];

    [self.viewSelector addTarget:self
                          action:@selector(viewSelectorChanged:)
                forControlEvents:UIControlEventValueChanged];


    self.bundleManagementViewController = [[ZincBundleManagementViewController alloc] initWithRepo:self.repo];
    self.activityViewController = [[ZincActivityViewController alloc] initWithRepo:self.repo];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGRect toolBarFrame = self.toolBar.frame;
    toolBarFrame.origin.y = self.view.frame.size.height - kToolbarHeight;
    self.toolBar.frame = toolBarFrame;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.viewSelector.selectedSegmentIndex = 0;
    [self showContentViewAtIndex:0];
}

- (CGRect)contentFrame
{
    CGRect frame = self.view.bounds;
    frame.size.height -= kToolbarHeight;
    return frame;
}

- (void)showContentViewAtIndex:(NSUInteger)index
{
    if (index == kViewIndexBundles) {

        [self.activityViewController.view removeFromSuperview];

        [self.view addSubview:self.bundleManagementViewController.view];
        self.bundleManagementViewController.view.frame = [self contentFrame];

    } else if (index == kViewIndexActivity) {

        [self.bundleManagementViewController.view removeFromSuperview];

        [self.view addSubview:self.activityViewController.view];
        self.activityViewController.view.frame = [self contentFrame];

    } else {


    }
}

- (void)viewSelectorChanged:(id)sender
{
    [self showContentViewAtIndex:self.viewSelector.selectedSegmentIndex];
}

@end
