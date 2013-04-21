//
//  TokenKeyInputView.h
//  belugapad
//
//  Created by Nicholas Cartwright on 21/04/2013.
//
//

#import <UIKit/UIKit.h>
@protocol TokenKeyInputViewDelegate;

@interface TokenKeyInputView : UIView <UIKeyInput, UITextInputTraits>

@property (retain) id<TokenKeyInputViewDelegate> delegate;
@property (readonly, nonatomic, retain) NSString *text;
@property (readonly) BOOL isValid;

-(void)clearText;
@end

@protocol TokenKeyInputViewDelegate
-(void)tokenWasEdited:(TokenKeyInputView*)view;
-(void)tokenBecameValid:(TokenKeyInputView*)view;
-(void)tokenBecameInvalid:(TokenKeyInputView*)view;
@end