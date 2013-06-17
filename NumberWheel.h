//
//  NumberWheel.h
//  belugapad
//
//  Created by David Amphlett on 12/05/2013.
//
//

#import "CCPickerView.h"

@interface NumberWheel : CCNode <CCPickerViewDataSource, CCPickerViewDelegate>
{
    CCNode *w;
}

@property (nonatomic, retain) CCPickerView *pickerView;
@property (retain) CCSprite  *mySprite;
@property (retain) NSString *SpriteFileName;
@property (retain) NSString *UnderlaySpriteFileName;
@property (retain) CCLayer *RenderLayer;
@property CGPoint Position;
@property (retain) NSMutableArray *pickerViewSelection;
@property int Components;
@property int InputValue;
@property int OutputValue;
@property (retain) NSString *StrOutputValue;
@property (retain) CCLabelTTF *Label;
@property BOOL Locked;
@property BOOL HasDecimals;
@property BOOL HasNegative;
@property int ComponentWidth;
@property int ComponentHeight;
@property int ComponentSpacing;
@property (retain) id AssociatedObject;
@property (retain) NSString *fractionPart;
@property (retain) NumberWheel *fractionWheel;
@property (retain) NumberWheel *wholeWheel;
@property (retain) NumberWheel *fractionWheelN;
@property (retain) NumberWheel *fractionWheelD;


-(NumberWheel *)init; //WithRenderLayer:(CCLayer*)renderLayer;
-(void)setupNumberWheel;
-(void)showNumberWheel;
-(void)hideNumberWheel;
-(BOOL)numberWheelShowing;
-(void)updatePickerNumber:(NSString*)thisNumber;
@end
