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
#import "ZincUtils.h"
#import "UIImage+Zinc.h"

@interface AppDelegate()
@property (strong, nonatomic) BundleListViewController *viewController;
@end

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

- (void) testBundleImageLoading
{
    // NOTE: this should be a unit test, but they don't execute in the same 
    // evironment so I'm adding a little something here
    
    NSError* error = nil;
    
    NSString* dstDir = [ZincGetApplicationDocumentsDirectory() stringByAppendingPathComponent:@"testimages"];
    [[NSFileManager defaultManager] removeItemAtPath:dstDir error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:dstDir withIntermediateDirectories:YES attributes:nil error:&error];
    NSAssert(error==nil, @"failed to create dir");
    
    for (NSString* file in [NSArray arrayWithObjects:@"sphalerite.jpg", @"sphalerite@2x.jpg", nil]) {
        if (![[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:file ofType:nil] toPath:[dstDir stringByAppendingPathComponent:file] error:&error]) {
            NSLog(@"error: %@", error);
            abort();
        }
    }
         
    NSBundle* bundle = [NSBundle bundleWithPath:dstDir];
    UIImage* image1 = [UIImage imageNamed:@"sphalerite.jpg" inBundle:bundle];
    NSAssert(image1, @"image1 is nil");
    NSLog(@"image1: %@", NSStringFromCGSize(image1.size));
    
    UIImage* image2 = [UIImage imageNamed:@"sphalerite@2x.jpg" inBundle:bundle];
    NSAssert(image2, @"image1 is nil");
    NSLog(@"image2: %@", NSStringFromCGSize(image2.size));

    if ([UIScreen mainScreen].scale == 2.0f) {
        NSAssert(image1.size.width == image2.size.width, @"retina wrong");
        
    } else {
        NSAssert(image1.size.width*2 == image2.size.width, @"non-retina wrong");
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    [self testBundleImageLoading];
    
    NSError* error = nil;
    
    NSURL* repoURL = [NSURL fileURLWithPath:
                      [AMGetApplicationDocumentsDirectory()
                       stringByAppendingPathComponent:@"zinc"]];
    
    NSLog(@"repo path: %@", [repoURL path]);
    
    BOOL needToBootStrap = ![ZincRepo repoExistsAtURL:repoURL];
    
    ZincRepo* repo = [[ZincRepo repoWithURL:repoURL error:&error] retain];
    repo.delegate = self;

    if (needToBootStrap) {
        
        [repo addSourceURL:[NSURL URLWithString:@"https://s3.amazonaws.com/zinc-demo/french4/"]];    
        
        [repo refreshSourcesWithCompletion:^{
            
            NSLog(@"refreshed!");

            NSString* bootstrapManifestPath = [[NSBundle mainBundle] pathForResource:@"com.mindsnacks.demo1.sphalerites-1" ofType:@"json"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.demo1.sphalerites" distribution:@"master" localManifestPath:bootstrapManifestPath];
            
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.AdvancedNumbers" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.AtThePharmacy" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.BasicAdjectives" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.BasicGreetings" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.BasicPrepositions" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.BodyParts" distribution:@"master"];
            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.CestVsIlEst" distribution:@"master"];
            
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.CommandsInFrench" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.Comparisons" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.DaysAndColors" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.Emotions" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.ExploringTheCity" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.ExpressionsWithEtre" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.FrequencyExpressions" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.GettingAroundTown" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.GoingShopping" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.IntroToNumbers" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.IntroducingGender" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.IntroducingPlural" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.LearnWhatYouEat" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.LetsGoToTheRestaurant" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.LikesAndDislikes" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.MonthsAndSeasons" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.MoreAdvancedNumbers" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.MoreGreetings" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.MoreShopping" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.Nightlife" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.PluralAdjectives" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.Possessives" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.PostOfficeAndTheBank" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.ProfessionsAndTitles" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.Regular-erVerbs" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.Regular-irVerbs" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.SportyVocabulary" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.TaxiAdventures" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.TheFamily" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.TheHouse" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.TheWeather" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.TimeAndDate" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.ToTheMovies" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.UsingAller" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.UsingAvoir" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.UsingAvoirSomeMore" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.UsingEtre" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.UsingFaire" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.UsingMettre" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.UsingPrendre" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.VacationPart2" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.VacationSurvivalPhrases" distribution:@"master"];
//            [repo beginTrackingBundleWithId:@"com.mindsnacks.french4.VacationTime" distribution:@"master"];
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
