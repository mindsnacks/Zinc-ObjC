//
//  ZincBundleDetailViewController.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/8/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincBundleDetailViewController.h"

#import "ZincRepo+Private.h"
#import "ZincRepoIndex.h"
#import "ZincInternals.h"
#import "ZincBundleDetailCell.h"


enum kSections {
    kTrackingSection,
    kVersionsSection,
    kDistrosSection,
    kSectionCount,
    };

enum kTags {
    kTrackNewDistroAlertTag = 100,
    kTrackNewCustomDistroAlertTag,
    };


@interface ZincBundleDetailViewController ()

@property (nonatomic, strong, readwrite) NSString *bundleID;
@property (nonatomic, strong, readwrite) ZincRepo *repo;
@property (nonatomic, strong, readwrite) NSDictionary *versionsByDistro;
@property (nonatomic, strong, readwrite) NSDictionary *distrosByVersion;
@property (nonatomic, strong, readwrite) NSArray *sortedDistros;

@end


@implementation ZincBundleDetailViewController

- (id)initWithBundleID:(NSString *)bundleID repo:(ZincRepo *)repo
{
    NSParameterAssert(bundleID);
    NSParameterAssert(repo);

    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.bundleID = bundleID;
        self.repo = repo;
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    return [self initWithBundleID:nil repo:nil];
}

- (void)refresh
{
    NSError *error = nil;

    NSString *catalogID = ZincCatalogIDFromBundleID(self.bundleID);
    ZincCatalog *catalog = [self.repo catalogWithIdentifier:catalogID error:&error];

    if (catalog == nil) {
        // TODO: present error;
    } else {

        self.versionsByDistro = [catalog distributionsForBundleName:ZincBundleNameFromBundleID(self.bundleID)];

        NSMutableDictionary *distrosByVersion = [[NSMutableDictionary alloc] init];

        [self.versionsByDistro enumerateKeysAndObjectsUsingBlock:^(NSString *distro, NSNumber *version, BOOL *stop) {

            NSMutableArray *distros = distrosByVersion[version];
            if (distros == nil) {
                distros = [[NSMutableArray alloc] init];
                distrosByVersion[version] = distros;
            }
            [distros addObject:distro];
        }];

        self.distrosByVersion = distrosByVersion;

        self.sortedDistros = [[self.versionsByDistro allKeys] sortedArrayUsingSelector:@selector(compare:)];
    }
}

- (void)loadView
{
    [super loadView];

    [self.tableView registerClass:[ZincBundleDetailCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self refresh];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == kTrackingSection) {
        return NSLocalizedString(@"Tracking", nil);

    } else if (section == kVersionsSection) {
        return NSLocalizedString(@"Available Local Versions", nil);

    } else if (section == kDistrosSection) {
        return NSLocalizedString(@"Available Distros", nil);
    }

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kTrackingSection) {
        return 1;

    } else if (section == kVersionsSection) {
        return [[self.repo.index availableVersionsForBundleID:self.bundleID] count];

    } else if (section == kDistrosSection) {
        return [self.sortedDistros count];
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    if (indexPath.section == kTrackingSection) {

        cell.textLabel.text = [self.repo trackedDistributionForBundleID:self.bundleID];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

    } else if (indexPath.section == kVersionsSection) {

        NSNumber *version = [self.repo.index availableVersionsForBundleID:self.bundleID][indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@", version];

        cell.detailTextLabel.text = [self.distrosByVersion[version] componentsJoinedByString:@", "];

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    } else if (indexPath.section == kDistrosSection) {

        NSString *distro = self.sortedDistros[indexPath.row];
        cell.textLabel.text = distro;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",
                                     self.versionsByDistro[distro]];


        NSString *trackedDisto = [self.repo trackedDistributionForBundleID:self.bundleID];
        if (![trackedDisto isEqualToString:distro]) {
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    return cell;
}

- (void)showTrackNewCustomDistroAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Track Custom Distro"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Track", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = kTrackNewCustomDistroAlertTag;
    [alert show];
}

- (void)showTrackNewDistroAlertWithDistro:(NSString *)distro
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Track New Distro?"
                                                    message:distro
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Track", nil];
    alert.tag = kTrackNewDistroAlertTag;
    [alert show];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kTrackingSection && indexPath.row == 0) {

        [self showTrackNewCustomDistroAlert];

    } else if (indexPath.section == kDistrosSection) {

        NSString *disto = self.sortedDistros[indexPath.row];

        [self showTrackNewDistroAlertWithDistro:disto];

    }
}


- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kTrackNewCustomDistroAlertTag) {

        if (buttonIndex == 1) {

            NSString *newDistro = [alertView textFieldAtIndex:0].text;
            [self.repo beginTrackingBundleWithID:self.bundleID distribution:newDistro];

            [self.tableView reloadData];
        }


    } else if (alertView.tag == kTrackNewDistroAlertTag) {

        if (buttonIndex == 1) {
            NSString *newDistro = [alertView message]; // TODO: this is hacky
            [self.repo beginTrackingBundleWithID:self.bundleID distribution:newDistro];

            [self.tableView reloadData];

        }
    }

}

@end
