//
//  AppDelegate.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <UIKit/UIKit.h>

<<<<<<< HEAD
@class RootViewController, UsersService;
=======
@class RootViewController, ContentService;
>>>>>>> refs/heads/development

@interface AppDelegate : NSObject <UIApplicationDelegate>
{
	UIWindow			*window;
	RootViewController	*viewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) NSDictionary *LocalSettings;
<<<<<<< HEAD
@property (nonatomic, retain) UsersService *usersService;

-(void)proceedFromLoginViaIntro:(BOOL)viaIntro;
=======
@property (nonatomic, readonly) ContentService *contentService;
>>>>>>> refs/heads/development

@end
