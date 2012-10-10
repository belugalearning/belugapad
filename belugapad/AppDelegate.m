//
//  AppDelegate.m
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import "AppDelegate.h"
#import "global.h"
#import "cocos2d.h"
#import "LoggingService.h"
#import "ContentService.h"
#import "UsersService.h"
#import "SelectUserViewController.h"
#import "LoadingViewController.h"
#import "ZubiIntro.h"
#import "JMap.h"
#import "ToolHost.h"
#import "mach/mach.h"
#import "TestFlight.h"

@interface AppController()
{
@private
    SelectUserViewController *selectUserViewController;
    BOOL cocosIsInitialised;
}
@property (nonatomic, readwrite) LoggingService *loggingService;
@property (nonatomic, readwrite) ContentService *contentService;
@property (nonatomic, readwrite) UsersService *usersService;
@end


@implementation AppController

@synthesize window=window_, navController=navController_, director=director_;

@synthesize loggingService;
@synthesize contentService;
@synthesize usersService;

@synthesize LocalSettings;
@synthesize ReleaseMode;
@synthesize IsIpad1;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self writeLogMemoryUsage];
    
    launchOptionsCache=launchOptions;
    
    // Init the window
    window_ = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    LoadingViewController *lvc=[[LoadingViewController alloc] init];
    [window_ setRootViewController:lvc];
    //[self.window addSubview:lvc.view];
    [self.window makeKeyAndVisible];
    [lvc release];
    
    // Try to use CADisplayLink director
    // if it fails (SDK < 3.1) use the default director
    
    //todo: no cc2 equiv
    //if( ! [CCDirector setDirectorType:kCCDirectorTypeDisplayLink] )
    //    [CCDirector setDirectorType:kCCDirectorTypeDefault];
    
    //init test flight
#define DO_THING_THAT_APPLE_DOES_NOT_LIKE 1
#if DO_THING_THAT_APPLE_DOES_NOT_LIKE
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#endif
    [TestFlight setOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"logToSTDERR"]];
    [TestFlight setOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"logToConsole"]];
    [TestFlight takeOff:@"1131d68d003b6409566d9ada07cd6caa_NTg2MjMyMDEyLTAyLTA0IDEwOjU4OjI2LjI0NTYyNg"];
    
    
    //load local settings
    self.LocalSettings=[NSDictionary dictionaryWithContentsOfFile:BUNDLE_FULL_PATH(@"/settings/local-settings.plist")];
    if ((BOOL)[self.LocalSettings valueForKey:@"RELEASE_MODE"])
    {
        [self.LocalSettings setValue:@"DATABASE" forKey:@"PROBLEM_PIPELINE"];
        [self.LocalSettings setValue:NO forKey:@"IMPORT_CONTENT_ON_LAUNCH"];
    }
    
    //load adaptive pipeline settings
    self.AdplineSettings=[NSDictionary dictionaryWithContentsOfFile:BUNDLE_FULL_PATH(@"/settings/adpline-settings.plist")];
    
    NSString *pl = [self.LocalSettings objectForKey:@"PROBLEM_PIPELINE"];
    BL_LOGGING_SETTING paLogging = [@"DATABASE" isEqualToString:pl] ? BL_LOGGING_ENABLED : BL_LOGGING_DISABLED;
    
    loggingService = [[LoggingService alloc] initWithProblemAttemptLoggingSetting:paLogging];
    contentService = [[ContentService alloc] initWithLocalSettings:self.LocalSettings];
    usersService = [[UsersService alloc] initWithProblemPipeline:pl andLoggingService:self.loggingService];
    
    [self.loggingService logEvent:BL_APP_START withAdditionalData:nil];
    
    //are we in release mode
    NSNumber *relmode=[self.LocalSettings objectForKey:@"RELEASE_MODE"];
    if(relmode) if ([relmode boolValue]) self.ReleaseMode=YES;
    
    [TestFlight passCheckpoint:@"SETTINGS_LOADED"];
    
    //do cocos stuff
    //director_ = (CCDirectorIOS*) [CCDirector sharedDirector];
    //[director_ enableRetinaDisplay:NO];
    
    selectUserViewController = [[SelectUserViewController alloc] init];
    
    //[self.window addSubview:selectUserViewController.view];
    [self.window setRootViewController:selectUserViewController];
    [self.window makeKeyAndVisible];
    
    [TestFlight passCheckpoint:@"USER_LOGIN_INIT"];
    
    //no purpose in getting this -- it's not used
    //NSDictionary *launchOptions=launchOptionsCache;
    
    self.IsIpad1 = !(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
                     [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]);
    
    director_ = (CCDirectorIOS*) [CCDirector sharedDirector];
    
	// Create an CCGLView with a RGB565 color buffer, and a depth buffer of 0-bits
	CCGLView *glView = [CCGLView viewWithFrame:[window_ bounds]
								   pixelFormat:kEAGLColorFormatRGB565	//kEAGLColorFormatRGBA8
								   depthFormat:0	//GL_DEPTH_COMPONENT24_OES
							preserveBackbuffer:NO
									sharegroup:nil
								 multiSampling:!self.IsIpad1
							   numberOfSamples:(self.IsIpad1 ? 0 : 4)];
    
	director_ = (CCDirectorIOS*) [CCDirector sharedDirector];
    
	director_.wantsFullScreenLayout = YES;
    
	// Display FSP and SPF
    [director_ setDisplayStats:!self.ReleaseMode];
    
	// set FPS at 60
	[director_ setAnimationInterval:1.0/60];
    
	// attach the openglView to the director
	[director_ setView:glView];
    
	// for rotation and other messages
	[director_ setDelegate:self];
    
	// 2D projection
	[director_ setProjection:kCCDirectorProjection2D];
    //	[director setProjection:kCCDirectorProjection3D];
    
	// Enables High Res mode (Retina Display) on iPhone 4 and maintains low res on all other devices
	if( ! [director_ enableRetinaDisplay:NO] )
		CCLOG(@"Retina Display Not supported");
    
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    
	// When in iPhone RetinaDisplay, iPad, iPad RetinaDisplay mode, CCFileUtils will append the "-hd", "-ipad", "-ipadhd" to all loaded files
	// If the -hd, -ipad, -ipadhd files are not found, it will load the non-suffixed version
	[CCFileUtils setiPhoneRetinaDisplaySuffix:@"-hd"];		// Default on iPhone RetinaDisplay is "-hd"
	[CCFileUtils setiPadSuffix:@"-ipad"];					// Default on iPad is "" (empty string)
	[CCFileUtils setiPadRetinaDisplaySuffix:@"-ipadhd"];	// Default on iPad RetinaDisplay is "-ipadhd"
    
	// Assume that PVR images have premultiplied alpha
	[CCTexture2D PVRImagesHavePremultipliedAlpha:YES];
    
    return YES;
}

-(void)proceedFromLoginViaIntro:(BOOL)viaIntro
{
	// Create a Navigation Controller with the Director
	navController_ = [[UINavigationController alloc] initWithRootViewController:director_];
	navController_.navigationBarHidden = YES;
    
	// set the Navigation Controller as the root view controller
    [window_ setRootViewController:navController_];
	//[window_ addSubview:navController_.view];
    
	// make main window visible
	[window_ makeKeyAndVisible]; 
    
    CCScene *currentScene;
    
    if(contentService.isUsingTestPipeline)
    {
        [TestFlight passCheckpoint:@"PROCEEDING_TO_TOOLHOST_FROM_LOGIN"];
        
        currentScene=[ToolHost scene];
    }
    else
    {
        [TestFlight passCheckpoint:@"PROCEEDING_TO_JMAP_FROM_LOGIN"];
        
        currentScene=[JMap scene];
    }
    [director_ pushScene:currentScene];
}

-(void)returnToLogin
{
    [TestFlight passCheckpoint:@"RETURNING_TO_LOGIN"];
    
    [self.window.rootViewController removeFromParentViewController];
    
    [[director_ runningScene] removeFromParentAndCleanup:YES];

    if (selectUserViewController)
    {
        [selectUserViewController release];
        selectUserViewController = nil;
    }

    [self.contentService updateContentDatabaseWithSettings:self.LocalSettings];
    
    selectUserViewController = [[SelectUserViewController alloc] init];
    
    //[self.window addSubview:selectUserViewController.view];
    [self.window setRootViewController:selectUserViewController];
    [self.window makeKeyAndVisible];

    
//    [navController_.view removeFromSuperview];
//    if (selectUserViewController)
//    {
//        [selectUserViewController release];
//        selectUserViewController = nil;
//    }
//    
//    [self.contentService updateContentDatabaseWithSettings:self.LocalSettings];
//    
//    selectUserViewController = [[SelectUserViewController alloc] init];    
//    [window_ addSubview:selectUserViewController.view];
//    [window_ makeKeyAndVisible];
}


// Supported orientations: Landscape. Customize it for your own needs
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


// getting a call, pause the game
-(void) applicationWillResignActive:(UIApplication *)application
{
    [loggingService logEvent:BL_APP_RESIGN_ACTIVE withAdditionalData:nil];
	if( [navController_ visibleViewController] == director_ )
		[director_ pause];
}

// call got rejected
-(void) applicationDidBecomeActive:(UIApplication *)application
{
    [loggingService logEvent:BL_APP_BECOME_ACTIVE withAdditionalData:nil];
	if( [navController_ visibleViewController] == director_ )
		[director_ resume];
}

-(void) applicationDidEnterBackground:(UIApplication*)application
{
    [loggingService logEvent:BL_APP_ENTER_BACKGROUND withAdditionalData:nil];
	if( [navController_ visibleViewController] == director_ )
		[director_ stopAnimation];
}

-(void) applicationWillEnterForeground:(UIApplication*)application
{
    [loggingService logEvent:BL_APP_ENTER_FOREGROUND withAdditionalData:nil];
	if( [navController_ visibleViewController] == director_ )
		[director_ startAnimation];
}

// application will be killed
- (void)applicationWillTerminate:(UIApplication *)application
{
    [loggingService logEvent:BL_APP_ABANDON withAdditionalData:nil];
	CC_DIRECTOR_END();
}

// purge memory
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    [loggingService logEvent:BL_APP_MEMORY_WARNING withAdditionalData:nil];
    
    NSLog(@"logging memory warning in appdelegate");
    
	[[CCDirector sharedDirector] purgeCachedData];
}

// next delta time will be zero
-(void) applicationSignificantTimeChange:(UIApplication *)application
{
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

vm_size_t usedMemory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

vm_size_t freeMemory(void) {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    
    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return vm_stat.free_count * pagesize;
}

-(void)writeLogMemoryUsage
{
    logMemUsage();
    
    [self performSelector:@selector(writeLogMemoryUsage) withObject:nil afterDelay:1.0f];
}

void logMemUsage(void) {
    // compute memory usage and log if different by >= 100k
    static long prevMemUsage = 0;
    long curMemUsage = usedMemory();
    long memUsageDiff = curMemUsage - prevMemUsage;
    
    if (memUsageDiff > 100000 || memUsageDiff < -100000) {
        prevMemUsage = curMemUsage;
        NSLog(@"Memory used %7.1f (%+5.0f), free %7.1f kb", curMemUsage/1000.0f, memUsageDiff/1000.0f, freeMemory()/1000.0f);
    }
}

- (void) dealloc
{
    [loggingService release];
    [contentService release];
    [usersService release];
    
	[window_ release];
	[navController_ release];
    
	[super dealloc];
}
@end
