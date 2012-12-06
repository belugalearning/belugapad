//
//  DWNWheelGameObject.h
//  belugapad
//
//  Created by David Amphlett on 08/10/2012.
//
//

#import "DWGameObject.h"
#import "DWNWheelGameObject.h"
#import "CCPickerView.h"

@interface DWNWheelGameObject : DWGameObject

@property (retain) CCSprite  *mySprite;
@property (retain) NSString *SpriteFileName;
@property (retain) NSString *UnderlaySpriteFileName;
@property (retain) CCLayer *RenderLayer;
@property CGPoint Position;
@property (retain) NSMutableArray *pickerViewSelection;
@property (retain,nonatomic) CCPickerView *pickerView;
@property (retain) DWGameObject *AssociatedGO;
@property int Components;
@property int InputValue;
@property int OutputValue;
@property (retain) NSString *StrOutputValue;
@property (retain) CCLabelTTF *Label;
@property BOOL HasCountBubble;
@property CGPoint CountBubblePosition;
@property (retain) CCSprite *CountBubble;
@property (retain) CCLabelTTF *CountBubbleLabel;
@property (retain) CCLayer *CountBubbleRenderLayer;
@property BOOL Locked;
@property BOOL HasDecimals;
@property BOOL HasNegative;
@property int ComponentWidth;
@property int ComponentHeight;
@property int ComponentSpacing;

@end
