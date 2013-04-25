//
//  AppDelegate.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"

@class RootViewController, LoggingService, ContentService, UsersService, AppUState;

@class AcapelaLicense, AcapelaSpeech, AcapelaSetup;

@interface AppController : NSObject <UIApplicationDelegate, CCDirectorDelegate>
{
	UIWindow *window_;
	UINavigationController *navController_;
    
	CCDirectorIOS	*director_;							// weak ref
    
   	RootViewController	*viewController;
    
    NSDictionary *launchOptionsCache;
    
    NSDictionary *speechReplacement;
    
    //    AcapelaSpeech *MyAcaTTS;
    AcapelaLicense *MyAcaLicense;
    AcapelaSetup *SetupData;
    
    NSMutableDictionary *achievementsDictionary;
}

@property (nonatomic, retain) UIWindow *window;
@property (readonly) UINavigationController *navController;
@property (readonly) CCDirectorIOS *director;

@property (nonatomic, readonly) LoggingService *loggingService;
@property (nonatomic, readonly) ContentService *contentService;
@property (nonatomic, readonly) UsersService *usersService;

@property (nonatomic, readonly) AppUState *appustateService;

@property (nonatomic, retain) NSDictionary *LocalSettings;
@property (retain) NSDictionary *AdplineSettings;

@property BOOL ReleaseMode;
@property BOOL AuthoringMode;
@property BOOL IsMuted;
@property BOOL IsIpad1;
@property BOOL NumberShowing;
@property int PreviousNumber;

//uikit gubbins
@property (retain) UISearchBar *searchBar;
@property (retain) UITableView *searchList;

//user state across map changes
@property (retain) NSDictionary *lastJmapViewUState;

@property (retain) AcapelaSpeech *acaSpeech;
@property (retain) NSString *lastViewedNodeId;


-(void)proceedFromLoginViaIntro:(BOOL)viaIntro;
-(void)returnToLogin;
-(void)writeLogMemoryUsage;
-(void)tearDownUI;
-(void)speakString:(NSString*)speakThis;
-(void)stopAllSpeaking;
-(int)getToolhostNotifierCount;
-(int)returnAppType;
- (void) reportAchievement:(NSString*)identifier;

@end
