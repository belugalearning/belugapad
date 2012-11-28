//
//  PassCodeInput.h
//  belugapad
//
//  Created by Nicholas Cartwright on 13/11/2012.
//
//

#import <UIKit/UIKit.h>
#import "NumpadInputController.h"

@interface PassCodeView : UIView <NumpadInputControllerDelegate>

@property (readonly, nonatomic, retain) NSString *text;

-(void)buttonTappedWithText:(NSString*)buttonText;
-(void)clearText;

@end
