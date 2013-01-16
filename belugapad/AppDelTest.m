//
//  AppDelTest.m
//  belugapad
//
//  Created by gareth on 16/01/2013.
//
//

#import "AppDelTest.h"
#import "SelectUserViewController.h"

#import "global.h"

#import "LoggingService.h"
#import "ContentService.h"
#import "UsersService.h"

@implementation AppDelTest

@synthesize loggingService;
@synthesize contentService;
@synthesize usersService;
@synthesize LocalSettings;
@synthesize AdplineSettings;

@synthesize ReleaseMode;
@synthesize AuthoringMode;
@synthesize IsMuted;
@synthesize IsIpad1;

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //load adaptive pipeline settings
    self.AdplineSettings=[NSDictionary dictionaryWithContentsOfFile:BUNDLE_FULL_PATH(@"/settings/adpline-settings.plist")];
    
    NSString *pl = [self.LocalSettings objectForKey:@"PROBLEM_PIPELINE"];
    BL_LOGGING_SETTING paLogging = [@"DATABASE" isEqualToString:pl] ? BL_LOGGING_ENABLED : BL_LOGGING_DISABLED;
    
    loggingService = [[LoggingService alloc] initWithProblemAttemptLoggingSetting:paLogging];
    contentService = [[ContentService alloc] initWithLocalSettings:self.LocalSettings];
    usersService = [[UsersService alloc] initWithProblemPipeline:pl andLoggingService:self.loggingService];
    
    [self.loggingService logEvent:BL_APP_START withAdditionalData:nil];

    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    
    SelectUserViewController *svc = [[SelectUserViewController alloc] init];
    
    //[self.window addSubview:selectUserViewController.view];
    self.viewController=svc;
    self.window.rootViewController=self.viewController;
    [self.window makeKeyAndVisible];
    
//    self.viewController = [[[UIViewController alloc] initWithNibName:@"PBViewController" bundle:nil] autorelease];
//    self.window.rootViewController = self.viewController;
//    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
