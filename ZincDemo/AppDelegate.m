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
#import "ZincEvent.h"

@interface AppDelegate()
@property (strong, nonatomic) BundleListViewController *viewController;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (void) zincRepo:(ZincRepo*)repo didReceiveEvent:(ZincEvent*)event
{    
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
    NSError* error = nil;
    
    NSURL* repoURL = [NSURL fileURLWithPath:
                      [AMGetApplicationDocumentsDirectory()
                       stringByAppendingPathComponent:@"zinc"]];
    
    NSLog(@"repo path: %@", [repoURL path]);
    
    BOOL needToBootStrap = ![ZincRepo repoExistsAtURL:repoURL];
    
    ZincRepo* repo = [[ZincRepo repoWithURL:repoURL error:&error] retain];
    repo.delegate = self;

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
            
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.CommandsInFrench" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.Comparisons" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.DaysAndColors" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.Emotions" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.ExploringTheCity" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.ExpressionsWithEtre" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.FrequencyExpressions" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.GettingAroundTown" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.GoingShopping" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.IntroToNumbers" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.IntroducingGender" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.IntroducingPlural" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.LearnWhatYouEat" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.LetsGoToTheRestaurant" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.LikesAndDislikes" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.MonthsAndSeasons" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.MoreAdvancedNumbers" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.MoreGreetings" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.MoreShopping" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.Nightlife" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.PluralAdjectives" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.Possessives" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.PostOfficeAndTheBank" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.ProfessionsAndTitles" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.Regular-erVerbs" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.Regular-irVerbs" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.SportyVocabulary" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.TaxiAdventures" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.TheFamily" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.TheHouse" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.TheWeather" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.TimeAndDate" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.ToTheMovies" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingAller" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingAvoir" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingAvoirSomeMore" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingEtre" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingFaire" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingMettre" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.UsingPrendre" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.VacationPart2" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.VacationSurvivalPhrases" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french.VacationTime" distribution:@"master"];
        }];
    }
    
    BundleListViewController* bundleListViewController = [[[BundleListViewController alloc] initWithRepo:repo] autorelease];
    
    UINavigationController* nc = [[[UINavigationController alloc] initWithRootViewController:bundleListViewController] autorelease];
    
    self.viewController = bundleListViewController;
    self.window.rootViewController = nc;
    [self.window makeKeyAndVisible];
    
    
    return YES;
}

@end
