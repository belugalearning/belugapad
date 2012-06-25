//
//  AppDelegate.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"

@class RootViewController, LoggingService, ContentService, UsersService;

@interface AppController : NSObject <UIApplicationDelegate, CCDirectorDelegate>
{
	UIWindow *window_;
	UINavigationController *navController_;
    
	CCDirectorIOS	*director_;							// weak ref
    
   	RootViewController	*viewController;
    
    NSDictionary *launchOptionsCache;
}

@property (nonatomic, retain) UIWindow *window;
@property (readonly) UINavigationController *navController;
@property (readonly) CCDirectorIOS *director;

@property (nonatomic, readonly) LoggingService *loggingService;
@property (nonatomic, readonly) ContentService *contentService;
@property (nonatomic, readonly) UsersService *usersService;

@property (nonatomic, retain) NSDictionary *LocalSettings;
@property BOOL ReleaseMode;

-(void)proceedFromLoginViaIntro:(BOOL)viaIntro;
-(void)returnToLogin;

@end
