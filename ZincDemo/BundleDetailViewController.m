//
//  BundleDetailViewController.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 2/1/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "BundleDetailViewController.h"
#import <Zinc/Zinc.h>

#import "ZincRepo+Private.h"
#import "ZincManifest.h"
#import "ImageFileViewController.h"

@interface BundleDetailViewController ()
@property (nonatomic, retain) NSArray* files;
@end

@implementation BundleDetailViewController

@synthesize tableView = _tableView;
@synthesize bundle = _bundle;
@synthesize repo = _repo;
@synthesize files = _files;

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
    [_files release];
    [_bundle release];
    [_repo release];
    [_tableView release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.title = [NSString stringWithFormat:@"%@-%d", [ZincBundle bundleNameFromBundleID:self.bundle.bundleID], self.bundle.version];

    [self.bundle.repo bundleWithID:self.bundle.bundleID];
    
    ZincManifest* manifest = [self.repo manifestWithBundleID:self.bundle.bundleID version:self.bundle.version error:NULL];
    
    self.files = [[manifest allFiles] sortedArrayUsingSelector:@selector(compare:)];
    
//    NSString* manifestString = [[manifest dictionaryRepresentation] description];
//    
//    self.manifestTextView.text = manifestString;
//    
//    NSBundle* bundle = [self.bundle NSBundle];
//    NSString* path1 = [bundle pathForResource:@"Advanced Numbers" ofType:@"js"];
//    NSLog(@"path1: %@", path1);
//    NSString* path2 = [bundle pathForResource:@"Advanced Numbers.js"];
//    NSLog(@"path2: %@", path2);
//    
//    NSString* audioPath = [bundle pathForResource:@"audio/more-adv-numbers-20" ofType:@"caf"];
//    NSLog(@"audioPath: %@", audioPath);
//    
//    NSLog(@"id %@", self.bundle.bundleID);
}

- (void) viewDidAppear:(BOOL)animated
{
    [self.tableView deselectRowAtIndexPath:
     [self.tableView indexPathForSelectedRow]
                                  animated:YES];

    [super viewDidAppear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.files count];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSString* file = [self.files objectAtIndex:[indexPath row]];
    cell.textLabel.text = file;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* file = [self.files objectAtIndex:[indexPath row]];
    
    if ([[file pathExtension] isEqualToString:@"jpg"] ||
        [[file pathExtension] isEqualToString:@"jpeg"] ||
        [[file pathExtension] isEqualToString:@"png"]) {

        NSString* path = [self.bundle pathForResource:file];
        
        UIImage* image = [[[UIImage alloc] initWithContentsOfFile:path] autorelease];
    
        ImageFileViewController* vc = [[[ImageFileViewController alloc] initWithImage:image] autorelease];
        [self.navigationController pushViewController:vc animated:YES];
    }
    
}


@end
