//
//  AppDelegate.m
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import "ZubiIntro.h"
#import "JourneyScene.h"
#import "global.h"
#import "ContentService.h"
#import "ToolHost.h"

#import "cocos2d.h"

#import "AppDelegate.h"

#import "UsersService.h"
#import "SelectUserViewController.h"
#import "LoadingViewController.h"
#import <CouchCocoa/CouchCocoa.h>

@interface AppController()
{
@private
    SelectUserViewController *selectUserViewController;
}

@property (nonatomic, readwrite) ContentService *contentService;
@property (nonatomic, readwrite) UsersService *usersService;

@end

@implementation AppController

@synthesize window=window_, navController=navController_, director=director_;

@synthesize LocalSettings;
@synthesize ReleaseMode;

@synthesize contentService;

@synthesize usersService;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    launchOptionsCache=launchOptions;
    
    // Init the window
    window_ = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    LoadingViewController *lvc=[[LoadingViewController alloc] init];
    [self.window addSubview:lvc.view];
    [self.window makeKeyAndVisible];
    [lvc release];
    
    CouchEmbeddedServer* server = [CouchEmbeddedServer sharedInstance];
    
    // install canned copy of any databases that don't yet exist (i.e. all of them on first app launch, hopefully none of them afterwards)
    [server.couchbase installDefaultDatabase:BUNDLE_FULL_PATH(@"/canned-dbs/may2012-users.couch")];    
    [server.couchbase installDefaultDatabase:BUNDLE_FULL_PATH(@"/canned-dbs/may2012-logging.couch")];
    
    [server start: ^{
        NSAssert(!server.error, @"Error launching Couchbase: %@", server.error);
        
        // Try to use CADisplayLink director
        // if it fails (SDK < 3.1) use the default director
        
        //todo: no cc2 equiv
        //if( ! [CCDirector setDirectorType:kCCDirectorTypeDisplayLink] )
        //    [CCDirector setDirectorType:kCCDirectorTypeDefault];
        
        //load local settings
        self.LocalSettings=[NSDictionary dictionaryWithContentsOfFile:BUNDLE_FULL_PATH(@"/local-settings.plist")];
        
        self.usersService = [[UsersService alloc] initWithProblemPipeline:[self.LocalSettings objectForKey:@"PROBLEM_PIPELINE"]];
        self.contentService = [[ContentService alloc] initWithProblemPipeline:[self.LocalSettings objectForKey:@"PROBLEM_PIPELINE"]];
        
        //are we in release mode
        NSNumber *relmode=[self.LocalSettings objectForKey:@"RELEASE_MODE"];
        if(relmode) if ([relmode boolValue]) self.ReleaseMode=YES;
        
        //do cocos stuff
        //director_ = (CCDirectorIOS*) [CCDirector sharedDirector];
        //[director_ enableRetinaDisplay:NO];
        
        selectUserViewController = [[SelectUserViewController alloc] init];
        
        [self.window addSubview:selectUserViewController.view];
        [self.window makeKeyAndVisible];
    }];
    
    return YES;
}

-(void)proceedFromLoginViaIntro:(BOOL)viaIntro
{
    //no purpose in getting this -- it's not used
    //NSDictionary *launchOptions=launchOptionsCache;
    
    director_ = (CCDirectorIOS*) [CCDirector sharedDirector];
    
	// Create an CCGLView with a RGB565 color buffer, and a depth buffer of 0-bits
	CCGLView *glView = [CCGLView viewWithFrame:[window_ bounds]
								   pixelFormat:kEAGLColorFormatRGB565	//kEAGLColorFormatRGBA8
								   depthFormat:0	//GL_DEPTH_COMPONENT24_OES
							preserveBackbuffer:NO
									sharegroup:nil
								 multiSampling:NO
							   numberOfSamples:0];
    
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
    
	// Create a Navigation Controller with the Director
	navController_ = [[UINavigationController alloc] initWithRootViewController:director_];
	navController_.navigationBarHidden = YES;
    
	// set the Navigation Controller as the root view controller
    //	[window_ setRootViewController:rootViewController_];
	[window_ addSubview:navController_.view];
    
	// make main window visible
	[window_ makeKeyAndVisible];
    
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

    
    // and add the scene to the stack. The director will run it when it automatically when the view is displayed.
	//[director_ pushScene: (viaIntro ? [ZubiIntro scene] : [JourneyScene scene])]; 
    
    if(contentService.isUsingTestPipeline)
    {
        [director_ pushScene:[ToolHost scene]];
    }
    else
    {
        [director_ pushScene:[JourneyScene scene]];
    }    
}

-(void)returnToLogin
{
    [navController_.view removeFromSuperview];
    if (selectUserViewController)
    {
        [selectUserViewController release];
        selectUserViewController = nil;
    }
    selectUserViewController = [[SelectUserViewController alloc] init];    
    [window_ addSubview:selectUserViewController.view];
    [window_ makeKeyAndVisible];
}

// Supported orientations: Landscape. Customize it for your own needs
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


// getting a call, pause the game
-(void) applicationWillResignActive:(UIApplication *)application
{
    [usersService logEvent:BL_APP_RESIGN_ACTIVE withAdditionalData:nil];
	if( [navController_ visibleViewController] == director_ )
		[director_ pause];
}

// call got rejected
-(void) applicationDidBecomeActive:(UIApplication *)application
{
    [usersService logEvent:BL_APP_BECOME_ACTIVE withAdditionalData:nil];
	if( [navController_ visibleViewController] == director_ )
		[director_ resume];
}

-(void) applicationDidEnterBackground:(UIApplication*)application
{
    [usersService logEvent:BL_APP_ENTER_BACKGROUND withAdditionalData:nil];
	if( [navController_ visibleViewController] == director_ )
		[director_ stopAnimation];
}

-(void) applicationWillEnterForeground:(UIApplication*)application
{
    [usersService logEvent:BL_APP_ENTER_FOREGROUND withAdditionalData:nil];
	if( [navController_ visibleViewController] == director_ )
		[director_ startAnimation];
}

// application will be killed
- (void)applicationWillTerminate:(UIApplication *)application
{
    [usersService logEvent:BL_APP_ABANDON withAdditionalData:nil];
	CC_DIRECTOR_END();
}

// purge memory
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    [usersService logEvent:BL_APP_MEMORY_WARNING withAdditionalData:nil];
	[[CCDirector sharedDirector] purgeCachedData];
}

// next delta time will be zero
-(void) applicationSignificantTimeChange:(UIApplication *)application
{
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (void) dealloc
{
    [contentService release];
    [usersService release];
    
	[window_ release];
	[navController_ release];
    
	[super dealloc];
}
@end
