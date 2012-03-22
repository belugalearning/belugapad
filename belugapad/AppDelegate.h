//
//  AppDelegate.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController, ContentService, UsersService, User;

@interface AppDelegate : NSObject <UIApplicationDelegate>
{
	UIWindow			*window;
	RootViewController	*viewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) NSDictionary *LocalSettings;
@property (nonatomic, readonly) ContentService *contentService;
@property (nonatomic, readonly) UsersService *usersService;
@property (retain) User *currentUser;

-(void)proceedFromLoginViaIntro:(BOOL)viaIntro;

@end
