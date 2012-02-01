//
//  AppDelegate.m
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "AppDelegate.h"

//#import "ViewController.h"
#import "BundleListViewController.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"


@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

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
    // Override point for customization after application launch.
    //    self.viewController = [[[ViewController alloc] initWithNibName:@"ViewController" bundle:nil] autorelease];
    
    //    NSString* dir = [[NSBundle mainBundle] pathForResource:@"Nightlife" ofType:nil];
    //    
    //    ZCBundle* zbundle = [[ZCBundle alloc] initWithPath:dir];
    
    
    //    Zincself.repo* zc = [Zincself.repo defaultself.repo];
    NSError* error = nil;
    
    NSURL* repoURL = [NSURL fileURLWithPath:
                      [AMGetApplicationDocumentsDirectory()
                       stringByAppendingPathComponent:@"zinc"]];
    
    NSLog(@"repo path: %@", [repoURL path]);
    
    BOOL needToBootStrap = ![ZincRepo repoExistsAtURL:repoURL];
    
    ZincRepo* repo = [[ZincRepo repoWithURL:repoURL error:&error] retain];
    repo.delegate = self;
    
    //    self.viewController.repo = repo;
    
    //    [[NSFileManager defaultManager] removeItemAtURL:repo.url error:NULL];
    
    
    
    //    [zc addSourceURL:[NSURL URLWithString:@"https://s3.amazonaws.com/zinc-demo/demo1/"]];
    //    [zc addSourceURL:[NSURL URLWithString:@"https://s3.amazonaws.com/zinc-demo/demo2/"]];
    //    [zc addSourceURL:[NSURL URLWithString:@"https://s3.amazonaws.com/zinc-demo/demo3/"]];
    //    [zc refreshSourcesWithCompletion:nil];
    //    
    ////    [zc beginTrackingBundleWithIdentifier:@"com.mindsnacks.zinc.demo1.fr-Nightlife" distribution:@"test"];
    //
    //    NSBundle* bundle = [zc bundleWithId:@"com.mindsnacks.zinc.demo1.fr-Nightlife" distribution:@"test"];
    //    
    //    NSString* p1 = nil;
    //
    //    p1 = [bundle pathForResource:@"turtle_strawberry" ofType:@"jpeg"];
    //    NSLog(@"%@", p1);
    //    
    //    p1 = [bundle pathForResource:@"audio/night-out-3" ofType:@"caf"];
    //    NSLog(@"%@", p1);
    
    if (needToBootStrap) {
        
        [repo addSourceURL:[NSURL URLWithString:@"https://s3.amazonaws.com/zinc-demo/french3/"]];    
        
        [repo refreshSourcesWithCompletion:^{
            
            NSLog(@"refreshed!");
            
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.AdvancedNumbers" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.AtThePharmacy" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.BasicAdjectives" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.BasicGreetings" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.BasicPrepositions" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.BodyParts" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.CestVsIlEst" distribution:@"master"];
            
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.CommandsInFrench" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.Comparisons" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.DaysAndColors" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.Emotions" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.ExploringTheCity" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.ExpressionsWithEtre" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.FrequencyExpressions" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.GettingAroundTown" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.GoingShopping" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.IntroToNumbers" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.IntroducingGender" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.IntroducingPlural" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.LearnWhatYouEat" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.LetsGoToTheRestaurant" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.LikesAndDislikes" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.MonthsAndSeasons" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.MoreAdvancedNumbers" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.MoreGreetings" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.MoreShopping" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.Nightlife" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.PluralAdjectives" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.Possessives" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.PostOfficeAndTheBank" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.ProfessionsAndTitles" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.Regular-erVerbs" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.Regular-irVerbs" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.SportyVocabulary" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.TaxiAdventures" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.TheFamily" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.TheHouse" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.TheWeather" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.TimeAndDate" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.ToTheMovies" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingAller" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingAvoir" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingAvoirSomeMore" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingEtre" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingFaire" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingMettre" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingPrendre" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.VacationPart2" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.VacationSurvivalPhrases" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.VacationTime" distribution:@"master"];
        }];
    }
    
    BundleListViewController* bundleListViewController = [[[BundleListViewController alloc] initWithRepo:repo] autorelease];
    self.viewController = bundleListViewController;
    self.window.rootViewController = bundleListViewController;
    [self.window makeKeyAndVisible];
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
