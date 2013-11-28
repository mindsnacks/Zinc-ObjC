//
//  ZincBundleContentsViewController.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 11/26/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincBundleContentsViewController.h"

#import "ZincManifest.h"
#import "ZincImageFileViewController.h"

#define kDirectoryPrefix @"📁"

@interface ZincBundleContentsViewController ()
@property (nonatomic, strong) ZincManifest *manifest;
@property (nonatomic, strong) NSString *rootPath;
@property (nonatomic, strong) NSString *subPath;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSMutableDictionary *directoryCache;

@end


@interface ZincBundleContentsCell : UITableViewCell
@end

@implementation ZincBundleContentsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.detailTextLabel.adjustsFontSizeToFitWidth = YES;

    }
    return self;
}

@end


@implementation ZincBundleContentsViewController

- (id)initWithManifest:(ZincManifest *)manifest rootPath:(NSString *)rootPath;
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.manifest = manifest;
        self.rootPath = rootPath;
        self.title = [self.rootPath lastPathComponent];
        self.directoryCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)currentDirectory
{
    return self.subPath != nil ? [self.rootPath stringByAppendingPathComponent:self.subPath] : self.rootPath;
}

- (void)reload
{
    NSError *error = nil;

    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self currentDirectory] error:&error];
    // TODO: something with the error

    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[contents count]];

    for (NSString *f in contents) {

        NSString *bundlePath = self.subPath ? [self.subPath stringByAppendingPathComponent:f] : f;

        if ([self.manifest shaForFile:bundlePath] != nil) {
            [items addObject:f];
        }
    }

    self.items = items;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[ZincBundleContentsCell class] forCellReuseIdentifier:@"Cell"];

    [self reload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.items count];
}

- (NSArray *)supportedViewerExtensions
{
    return [ZincImageFileViewController supportedExtensions];
}

- (BOOL)isDirAtPath:(NSString *)path
{
    if (self.directoryCache[path] != nil) {
        return [self.directoryCache[path] boolValue];
    }

    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    self.directoryCache[path] = [NSNumber numberWithBool:isDir];

    return isDir;
}

- (NSString *)absolutePathAtIndex:(NSUInteger)index
{
    return [[self currentDirectory] stringByAppendingPathComponent:self.items[index]];
}

- (NSString *)bundlePathAtIndex:(NSUInteger)index
{
    return [[self absolutePathAtIndex:index] substringFromIndex:[self.rootPath length] + 1];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    NSString *filename = self.items[indexPath.row];
    NSString *absPath = [self absolutePathAtIndex:indexPath.row];
    NSString *bundlePath = [self bundlePathAtIndex:indexPath.row];
    NSString *text = filename;

    BOOL isDir = [self isDirAtPath:absPath];

    if (isDir) {

        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", kDirectoryPrefix, filename];

    } else  {

        cell.textLabel.text = filename;
        cell.detailTextLabel.text = [self.manifest shaForFile:bundlePath];

        if ([[self supportedViewerExtensions] containsObject:[[text pathExtension] lowercaseString]]) {

            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        } else {

            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    return cell;
}


- (void)didReceiveMemoryWarning
{
    self.directoryCache = [NSMutableDictionary dictionary];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *path = [self absolutePathAtIndex:indexPath.row];

    UIViewController *viewControllerToPush = nil;

    if ([self isDirAtPath:path]) {

        viewControllerToPush = [[ZincBundleContentsViewController alloc] initWithManifest:self.manifest rootPath:path];

    } else if ([[ZincImageFileViewController supportedExtensions] containsObject:[path pathExtension]]) {

        viewControllerToPush = [[ZincImageFileViewController alloc] initWitImagePath:path];
    }

    if (viewControllerToPush != nil) {
        [self.navigationController pushViewController:viewControllerToPush animated:YES];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

}

@end
