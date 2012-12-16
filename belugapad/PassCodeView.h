//
//  PassCodeInput.h
//  belugapad
//
//  Created by Nicholas Cartwright on 13/11/2012.
//
//

#import <UIKit/UIKit.h>
#import "NumpadInputController.h"
@protocol PassCodeViewDelegate;


@interface PassCodeView : UIView <NumpadInputControllerDelegate>

@property (retain) id<PassCodeViewDelegate> delegate;
@property (readonly, nonatomic, retain) NSString *text;
@property (readonly) BOOL isValid;

-(void)buttonTappedWithText:(NSString*)buttonText;
-(void)clearText;

@end



@protocol PassCodeViewDelegate
-(void)passCodeWasEdited:(PassCodeView*)pcv;
-(void)passCodeBecameValid:(PassCodeView*)pcv;
-(void)passCodeBecameInvalid:(PassCodeView*)pcv;
@end
