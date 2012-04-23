//
//  AppDelegate.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"

#import <Couchbase/CouchbaseMobile.h>

@class RootViewController, ContentService, UsersService, User;

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

@property (nonatomic, retain) NSDictionary *LocalSettings;
@property (nonatomic, readonly) ContentService *contentService;

@property (nonatomic, readonly) UsersService *usersService;
@property (retain) User *currentUser;

-(void)proceedFromLoginViaIntro:(BOOL)viaIntro;

@end
