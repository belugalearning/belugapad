//
//  DWNWheelGameObject.m
//  belugapad
//
//  Created by David Amphlett on 08/10/2012.
//
//

#import "DWNWheelGameObject.h"
#import "global.h"


@implementation DWNWheelGameObject


@synthesize mySprite;
@synthesize SpriteFileName;
@synthesize Position;
@synthesize RenderLayer;
@synthesize pickerViewSelection;
@synthesize pickerView;
@synthesize AssociatedGO;
@synthesize Components;
@synthesize InputValue;
@synthesize OutputValue;
@synthesize StrOutputValue;
@synthesize Label;
@synthesize HasCountBubble;
@synthesize CountBubblePosition;
@synthesize CountBubble;
@synthesize CountBubbleLabel;
@synthesize CountBubbleRenderLayer;
@synthesize Locked;
@synthesize HasDecimals;
@synthesize HasNegative;
@synthesize ComponentHeight;
@synthesize ComponentWidth;
@synthesize ComponentSpacing;
@synthesize UnderlaySpriteFileName;

-(void)dealloc
{
    self.mySprite=nil;
    self.SpriteFileName=nil;
    self.pickerViewSelection=nil;
    self.AssociatedGO=nil;
    self.pickerView=nil;
    self.RenderLayer=nil;
    self.Label=nil;
    self.CountBubble=nil;
    self.CountBubbleLabel=nil;
    self.CountBubbleRenderLayer=nil;
    
    [super dealloc];
}

@end
