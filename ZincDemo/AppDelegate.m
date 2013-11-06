//
//  AppDelegate.m
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "AppDelegate.h"

#import "BundleListViewController.h"


@interface AppDelegate()
@property (strong, nonatomic) BundleListViewController *viewController;
@end

@implementation AppDelegate


- (void) zincRepo:(ZincRepo*)repo didReceiveEvent:(ZincEvent*)event
{   
    NSLog(@"%@", event);
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    NSError* error = nil;
    
    NSURL* repoURL = [NSURL fileURLWithPath:
                      [ZincGetApplicationDocumentsDirectory()
                       stringByAppendingPathComponent:@"zinc"]];
    
    NSLog(@"repo path: %@", [repoURL path]);
    
    ZincRepo* repo = [[ZincRepo repoWithURL:repoURL error:&error] retain];
    repo.eventListener = self;
    
    [repo.downloadPolicy setDefaultRequiredConnectionType:ZincConnectionTypeWiFiOnly];
    
    [repo resumeAllTasks];

    // TODO: replace bootstrapping

//    NSArray* bundleIDsToBootstrap = [NSArray arrayWithObjects:
//                                     @"com.mindsnacks.demo1.cats",
//                                     @"com.mindsnacks.demo1.sphalerites", nil];
//
//
//    for (NSString* bundleID in bundleIDsToBootstrap) {
//        
//        ZincBundleTrackingRequest* req = [[[ZincBundleTrackingRequest alloc] init] autorelease];
//        req.bundleID = bundleID;
//        
//        [repo bootstrapBundleWithRequest:req fromDir:[[NSBundle mainBundle] resourcePath] completionBlock:^(NSArray *errors) {
//            if ([errors count] > 0) {
//                NSLog(@"%@", errors);
//                abort();
//            }
//            NSLog(@"bootstrapped %@", bundleID);
//        }];
//    }

    [repo addSourceURL:[NSURL URLWithString:@"https://s3.amazonaws.com/zinc-demo/com.mindsnacks.demo1/"]];
    
    [repo beginTrackingBundleWithID:@"com.mindsnacks.demo1.sphalerites" distribution:@"master"];

    [repo updateBundleWithID:@"com.mindsnacks.demo1.cats" completionBlock:^(NSArray *errors) {
    }];
    
    [repo updateBundleWithID:@"com.mindsnacks.demo1.sphalerites"];

    self.zincAgent = [ZincAgent agentForRepo:repo];

    BundleListViewController* bundleListViewController = [[[BundleListViewController alloc] initWithRepo:repo] autorelease];
    
    UINavigationController* nc = [[[UINavigationController alloc] initWithRootViewController:bundleListViewController] autorelease];
    
    self.viewController = bundleListViewController;
    self.window.rootViewController = nc;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
