//
//  SelectUserViewController.h
//  belugapad
//
//  Created by Nicholas Cartwright on 16/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AppDelegate;

@interface SelectUserViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
{
    IBOutlet UIImageView *backgroundImageView;
    IBOutlet UIView *selectUserView;
    IBOutlet UIView *editUserView;
    IBOutlet UIView *loadExistingUserView;
}
@end
