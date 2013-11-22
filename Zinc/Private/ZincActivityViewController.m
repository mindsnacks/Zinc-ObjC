//
//  DownloadsVC.m
//  MindSnacks
//
//  Created by Andy Mroczkowski on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZincActivityViewController.h"

#import "ZincRepo.h"
#import "ZincInternals.h"
#import "ZincRepoMonitor.h"
#import "ZincActivityCell.h"

@interface ZincActivityViewController ()

@property (nonatomic, retain) ZincRepo *repo;
@property (nonatomic, retain) ZincRepoMonitor *monitor;
@property (nonatomic, retain) NSArray *items;

@end


@implementation ZincActivityViewController

- (id) initWithRepo:(ZincRepo *)repo
{
    NSParameterAssert(repo);

    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.repo = repo;
        self.monitor = [[ZincRepoMonitor alloc] initWithRepo:repo taskPredicate:nil];

        self.title = NSLocalizedString(@"Activity", @"ZincActivityViewController title");
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    [super loadView];

    [self.tableView registerClass:[ZincActivityCell class] forCellReuseIdentifier:@"Cell"];

    self.view.backgroundColor = [UIColor whiteColor];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = 55;
}

- (void)monitorRefreshed:(NSNotification *)note
{
    self.items = [[self.monitor items] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        ZincActivityItem* item1 = obj1;
        ZincActivityItem* item2 = obj2;

        // NOTE: this sorts in DESCENDING order, because we want to most percentage at the top
        if (item1.progressPercentage < item2.progressPercentage) return NSOrderedDescending;
        if (item1.progressPercentage > item2.progressPercentage) return NSOrderedAscending;
        return NSOrderedSame;
    }];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Pause", @"Pause Button Title")
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(onPauseButtonPress)];

    self.navigationItem.rightBarButtonItem = rightButton;
}

- (void)onPauseButtonPress
{
    if ([self.repo isSuspended]) {
        [self.repo resumeAllTasks];
    } else {
        [self.repo suspendAllTasks];
    }
}

#pragma mark -

- (NSString *)textForCellAtIndexPath:(NSIndexPath *)indexPath
{
    ZincActivityItem* item = [self.items objectAtIndex:(NSUInteger)indexPath.row];

    if ([item.subject isKindOfClass:[ZincTask class]]) {

        NSString* bundleId = [[(ZincTask *)item.subject resource] zincBundleID];
        return bundleId;
    }

    return nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)[self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    ZincActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.progressView.progress = 0.0;

    cell.mainLabel.text = [self textForCellAtIndexPath:indexPath];
//    cell.textLabel.text = [self textForCellAtIndexPath:indexPath];

    ZincActivityItem *item = [self.items objectAtIndex:(NSUInteger)indexPath.row];

    const float newProgress = item.progressPercentage;

    if (newProgress > cell.progressView.progress)
    {
        cell.progressView.progress = newProgress;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ZincActivityCell cellHeightForText:[self textForCellAtIndexPath:indexPath] fitInWidth:self.view.frame.size.width];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(monitorRefreshed:)
                                                 name:ZincActivityMonitorRefreshedNotification
                                               object:self.monitor];

    [self.monitor startMonitoring];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.monitor stopMonitoring];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ZincActivityMonitorRefreshedNotification
                                                  object:self.monitor];

    [super viewDidDisappear:animated];
}


@end
