//
//  DWRamblerGameObject.h
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"

@class BNLineRamblerRender;

@interface DWRamblerGameObject : DWGameObject
{
    BNLineRamblerRender *bnRender;
}

-(void)readyRender;
-(void) drawFromMid:(CGPoint)mid andYOffset:(float)yOffset;

@property float Value;
@property float StartValue;
@property float DefaultSegmentSize;
@property float CurrentSegmentValue;
@property BOOL showJumpLabels;
@property CGPoint Pos;
@property (retain) NSNumber *MinValue;
@property (retain) NSNumber *MaxValue;

@property float TouchXOffset;
@property float HeldMoveOffsetX;

@property BOOL RenderStitches;
@property int AutoStitchIncrement;


@property int BubblePos;

@property BOOL HideStartNumber;
@property BOOL HideEndNumber;
@property BOOL HideAllNumbers;
@property (retain) NSArray *ShowNumbersAtIntervals;

@property BOOL HideStartNotch;
@property BOOL HideEndNotch;
@property BOOL HideAllNotches;
@property (retain) NSArray *ShowNotchesAtIntervals;

@property (retain) NSMutableArray *MarkerValuePositions;
@property (retain) NSMutableArray *UserJumps;

@property int DisplayNumberOffset;
@property float DisplayNumberMultiplier;
@property int DisplayNumberDP;
@property int DisplayDenominator;

@end
