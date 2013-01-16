//
//  AppDelTest.h
//  belugapad
//
//  Created by gareth on 16/01/2013.
//
//

#import <UIKit/UIKit.h>

@class LoggingService;
@class ContentService;
@class UsersService;

@interface AppDelTest : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UIViewController *viewController;

@property (nonatomic, readwrite) LoggingService *loggingService;
@property (nonatomic, readwrite) ContentService *contentService;
@property (nonatomic, readwrite) UsersService *usersService;

@property (nonatomic, retain) NSDictionary *LocalSettings;
@property (retain) NSDictionary *AdplineSettings;

@property BOOL ReleaseMode;
@property BOOL AuthoringMode;
@property BOOL IsMuted;
@property BOOL IsIpad1;

@end
