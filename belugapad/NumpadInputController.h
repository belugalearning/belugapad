//
//  NumpadInputController.h
//  belugapad
//
//  Created by Nicholas Cartwright on 27/11/2012.
//
//

#import <UIKit/UIKit.h>

@protocol NumpadInputControllerDelegate
-(void)buttonTappedWithText:(NSString*)buttonText;
@end

@interface NumpadInputController : UIViewController
{
    id<NumpadInputControllerDelegate> delegate;
}

@property (nonatomic, assign) id<NumpadInputControllerDelegate> delegate;

-(IBAction)buttonPress:(id)sender;

@end