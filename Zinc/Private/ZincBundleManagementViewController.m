//
//  ZincBundleManagementViewController.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/7/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincBundleManagementViewController.h"

#import "ZincRepo.h"
#import "ZincInternals.h"
#import "ZincBundleListViewController.h"


@interface ZincBundleManagementViewController ()
@property (nonatomic, strong, readwrite) ZincRepo *repo;
@end

@implementation ZincBundleManagementViewController

- (id)initWithRepo:(ZincRepo *)repo
{
    NSParameterAssert(repo);

    ZincBundleListViewController *listViewController = [[ZincBundleListViewController alloc] initWithRepo:repo];
    self = [super initWithRootViewController:listViewController];
    if (self) {
        self.repo = repo;
    }
    return self;
}

- (id)init
{
    return [self initWithRepo:nil];
}

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    return [self initWithRepo:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void)refresh
{
    [self.repo refreshSourcesWithCompletion:nil];
}

@end
