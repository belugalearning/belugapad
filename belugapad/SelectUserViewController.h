//
//  SelectUserViewController.h
//  belugapad
//
//  Created by Nicholas Cartwright on 16/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PassCodeView.h"

@class AppDelegate;
@class CODialog;

@interface SelectUserViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, PassCodeViewDelegate>
{
    IBOutlet UIImageView *backgroundImageView;
}
-(void)passCodeBecameInvalid:(PassCodeView*)passCodeView;
-(void)passCodeBecameValid:(PassCodeView*)passCodeView;

@property (nonatomic, strong) CODialog *dialog;

@end
