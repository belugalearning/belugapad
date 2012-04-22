//
//  SelectUserViewController.h
//  belugapad
//
//  Created by Nicholas Cartwright on 16/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RootViewController.h"
#import "ColorPickerImageView.h"
@class AppDelegate;

@interface SelectUserViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
{
    IBOutlet UIImageView *backgroundImageView;    
    IBOutlet UIView *selectUserView;    
    IBOutlet UIView *editUserView;
    IBOutlet UIView *loadExistingUserView;
}

//@property (retain, nonatomic) IBOutlet CouchUITableSource *dataSource;
@property (retain, nonatomic) IBOutlet ColorPickerImageView *colorWheel;

@end
