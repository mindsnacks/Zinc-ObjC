//
//  BundleListViewController.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/31/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "BundleListViewController.h"
#import <Zinc/Zinc.h>
#import "BundleDetailViewController.h"

@interface BundleListViewController ()
@property (nonatomic, retain, readwrite) ZincRepo* repo;
@property (nonatomic, retain) NSMutableArray* bundleIDs;

@property (nonatomic, retain) NSMutableDictionary *bundleProgress;
@end

@implementation BundleListViewController

@synthesize repo = _repo;
@synthesize bundleIDs = _bundleIDs;
@synthesize bundleProgress = _bundleProgress;

- (id) initWithRepo:(ZincRepo *)repo
{
    self = [self initWithStyle:UITableViewStylePlain];
    if (self) {
        _repo = [repo retain];
        _bundleIDs = [[NSMutableArray alloc] initWithArray:[[_repo trackedBundleIDs] allObjects]];
        _bundleProgress = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(bundleWillBeginTrackingNotification:) 
                                                     name:ZincRepoBundleDidBeginTrackingNotification
                                                   object:_repo];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(bundleWillDeleteNotification:) 
                                                     name:ZincRepoBundleWillDeleteNotification
                                                   object:_repo];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(bundleCloneCompleteNotification:)
                                                     name:kZincEventBundleCloneCompleteNotification
                                                   object:_repo];
    }
    return self;
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_repo release];
    [_bundleIDs release];
    [_bundleProgress release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Debug"
                                                                              style:UIBarButtonItemStylePlain 
                                                                             target:self
                                                                             action:@selector(debugAction:)] autorelease];
    

    self.title = @"Bundles";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.bundleIDs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSString* bundleID = [self.bundleIDs objectAtIndex:[indexPath row]];
    NSString* bundleName = ZincBundleNameFromBundleID(bundleID);
    ZincBundleState state = [self.repo stateForBundleWithID:bundleID];
    NSString *stateName = ZincBundleStateName[state];
    
    NSString *cellDetailText = stateName;

    if (state == ZincBundleStateCloning)
    {
        double downloadProgress = [[self.bundleProgress valueForKey:bundleID] doubleValue];
        
        if (downloadProgress == 1)
        {
            cellDetailText = @"Unpacking";
        }
        else
        {
            cellDetailText = [cellDetailText stringByAppendingFormat:@" (%d%%)", (int)(downloadProgress * 100)];
        }
    }
    
    cell.textLabel.text = bundleName;
    cell.detailTextLabel.text = cellDetailText;
    
    if (state == ZincBundleStateAvailable) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSString* bundleID = [self.bundleIDs objectAtIndex:[indexPath row]];
    ZincBundle* bundle = [self.repo bundleWithID:bundleID];

    BundleDetailViewController* vc = [[[BundleDetailViewController alloc] initWithBundle:bundle repo:self.repo] autorelease];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Actions

- (void) debugAction:(id)sender
{
    [self.repo updateBundleWithID:@"com.mindsnacks.demo1.sphalerites" completionBlock:^(NSArray *errors) {
        NSLog(@"updated! errors: %@", errors);
    }];
}

#pragma mark - Notifications

- (void) bundleWillBeginTrackingNotification:(NSNotification *)note
{
    NSString* bundleID = [[note userInfo] objectForKey:ZincRepoBundleChangeNotificationBundleIDKey];
    if (![self.bundleIDs containsObject:bundleID]) {
        [self.bundleIDs addObject:bundleID];
        [self.tableView reloadData];
    }
}

- (void)bundleCloneCompleteNotification:(NSNotification *)note
{
    NSString *bundleID = [note.userInfo valueForKey:kZincEventAttributesContextKey];
    
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.bundleIDs indexOfObject:bundleID]
                                                                                       inSection:0]]
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (void) bundleWillDeleteNotification:(NSNotification *)note
{
    //    NSString* bundleID = [[note userInfo] objectForKey:ZincRepoBundleChangeNotificationBundleIDKey];
    //[self.bundleIDs removeObject:bundleID];
}



@end
