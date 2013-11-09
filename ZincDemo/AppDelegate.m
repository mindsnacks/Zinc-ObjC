//
//  AppDelegate.m
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "AppDelegate.h"
#import "ZincAdminViewController.h"
#import "ZincBundleListViewController.h"



@implementation AppDelegate

- (void) zincRepo:(ZincRepo*)repo didReceiveEvent:(ZincEvent*)event
{   
    NSLog(@"%@", event);
}

- (void)dealloc
{
    [_window release];
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

    [repo addSourceURL:[NSURL URLWithString:@"https://s3.amazonaws.com/zinc-demo/com.mindsnacks.demo1/"]];
    
    [repo beginTrackingBundleWithID:@"com.mindsnacks.demo1.sphalerites" distribution:@"master"];
    [repo beginTrackingBundleWithID:@"com.mindsnacks.demo1.farts" distribution:@"develop"];
    [repo beginTrackingBundleWithID:@"com.mindsnacks.demo2.pineapples" distribution:@"master"];


    [repo updateBundleWithID:@"com.mindsnacks.demo1.cats" completionBlock:^(NSArray *errors) {
    }];
    
    [repo updateBundleWithID:@"com.mindsnacks.demo1.sphalerites"];

    self.zincAgent = [ZincAgent agentForRepo:repo];

    ZincAdminViewController *adminViewController = [[ZincAdminViewController alloc] initWithRepo:repo];

//    ZincBundleListViewController *adminViewController = [[ZincBundleListViewController alloc] initWithRepo:repo];

    self.window.rootViewController = adminViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
