//
//  BundleListViewController.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/31/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "BundleListViewController.h"
#import "Zinc.h"
#import "BundleDetailViewController.h"

@interface BundleListViewController ()
@property (nonatomic, retain, readwrite) ZincRepo* repo;
@property (nonatomic, retain) NSMutableArray* bundleIds;
@end

@implementation BundleListViewController

@synthesize repo = _repo;
@synthesize bundleIds = _bundleIds;

- (id) initWithRepo:(ZincRepo *)repo
{
    self = [self initWithStyle:UITableViewStylePlain];
    if (self) {
        _repo = [repo retain];
        _bundleIds = [[NSMutableArray alloc] initWithArray:[[_repo trackedBundleIds] allObjects]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(bundleWillBeginTrackingNotification:) 
                                                     name:ZincRepoBundleDidBeginTrackingNotification
                                                   object:_repo];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(bundleStatusChangeNotification:) 
                                                     name:ZincRepoBundleStatusChangeNotification
                                                   object:_repo];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(bundleWillDeleteNotification:) 
                                                     name:ZincRepoBundleWillDeleteNotification
                                                   object:_repo];
    }
    return self;
}

- (void) bundleWillBeginTrackingNotification:(NSNotification *)note
{
    NSString* bundleId = [[note userInfo] objectForKey:ZincRepoBundleChangeNotifiationBundleIdKey];
    [self.bundleIds addObject:bundleId];
    [self.tableView reloadData];
}

- (void) bundleStatusChangeNotification:(NSNotification *)note
{
    [self.tableView reloadData];
}

- (void) bundleWillDeleteNotification:(NSNotification *)note
{
//    NSString* bundleId = [[note userInfo] objectForKey:ZincRepoBundleChangeNotifiationBundleIdKey];
    //[self.bundleIds removeObject:bundleId];
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
    [super dealloc];
}

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

    self.title = @"Bundles";
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.bundleIds count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSString* bundleId = [self.bundleIds objectAtIndex:[indexPath row]];
    NSString* bundleName = [ZincBundle bundleNameFromBundleId:bundleId];
    ZincBundleState state = [self.repo stateForBundleWithId:bundleId];
    
//    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", bundleName, ZincBundleStateName[state]];
    cell.textLabel.text = bundleName;
    cell.detailTextLabel.text = ZincBundleStateName[state];
    
    if (state == ZincBundleStateAvailable) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    
    NSString* bundleId = [self.bundleIds objectAtIndex:[indexPath row]];
    ZincBundle* bundle = [self.repo bundleWithId:bundleId];

    BundleDetailViewController* vc = [[[BundleDetailViewController alloc] initWithBundle:bundle repo:self.repo] autorelease];
    [self.navigationController pushViewController:vc animated:YES];
}



@end
