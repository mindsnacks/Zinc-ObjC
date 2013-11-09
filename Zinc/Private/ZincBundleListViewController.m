//
//  ZincBundleListViewController.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/5/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincBundleListViewController.h"

#import "ZincRepo.h"
#import "ZincInternals.h"
#import "ZincBundleListViewDataSource.h"
#import "ZincBundleListViewCell.h"
#import "ZincBundleDetailViewController.h"

static NSString *const kAvailableSymbol = @"🔵";
static NSString *const kUnavailableSymbol = @"🔴";
static NSString *const kTrackingSymbol = @"→";

@interface ZincBundleListViewController ()

@property (nonatomic, strong, readwrite) ZincRepo *repo;
@property (nonatomic, strong, readwrite) ZincBundleListViewDataSource *dataSource;

@end

@implementation ZincBundleListViewController

- (id) initWithRepo:(ZincRepo *)repo
{
    NSParameterAssert(repo);

    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.repo = repo;
        self.dataSource = [[ZincBundleListViewDataSource alloc] initWithRepo:repo];
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    return [self initWithRepo:nil];
}

- (void)reload
{
    [self.dataSource reload];
    [self.tableView reloadData];
}

- (void)loadView
{
    [super loadView];

//    [self reload];

    self.title = NSLocalizedString(@"Bundles", @"ZincBundleListViewController title");

    [self.tableView registerClass:[ZincBundleListViewCell class] forCellReuseIdentifier:@"Cell"];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];

}

- (void)refresh
{
    __weak typeof(self) weakself = self;
    [self.repo refreshSourcesWithCompletion:^{

        __strong typeof(weakself) strongself = weakself;

        dispatch_async(dispatch_get_main_queue(), ^{
            [strongself reload];
        });
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self reload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.dataSource.sortedCatalogIDs count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource numberOfBundlesInCatalogAtIndex:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.dataSource.sortedCatalogIDs[section];
}

- (NSString *)statusSymbolForBundleID:(NSString *)bundleID
{
    ZincBundleState state = [self.repo stateForBundleWithID:bundleID];
    if (state == ZincBundleStateAvailable) {
        return kAvailableSymbol;
    }
    return kUnavailableSymbol;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    NSString *bundleID = [self.dataSource bundleIDAtIndexPath:indexPath];

    NSString *statusSymbol = [self statusSymbolForBundleID:bundleID];

    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@",
                           statusSymbol,
                           ZincBundleNameFromBundleID(bundleID)];

    NSString *distro = [self.repo trackedDistributionForBundleID:bundleID];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", kTrackingSymbol, distro];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *bundleID = [self.dataSource bundleIDAtIndexPath:indexPath];

    ZincBundleDetailViewController *detailVC = [[ZincBundleDetailViewController alloc] initWithBundleID:bundleID repo:self.repo];

    [self.navigationController pushViewController:detailVC animated:YES];
}


@end
