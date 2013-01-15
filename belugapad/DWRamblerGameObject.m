//
//  DWRamblerGameObject.m
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWRamblerGameObject.h"
#import "BNLineRamblerRender.h"

@implementation DWRamblerGameObject

@synthesize Value;
@synthesize StartValue;
@synthesize DefaultSegmentSize;
@synthesize CurrentSegmentValue;
@synthesize showJumpLabels;
@synthesize Pos;
@synthesize MinValue;
@synthesize MaxValue;

@synthesize TouchXOffset;
@synthesize HeldMoveOffsetX;

@synthesize RenderStitches;
@synthesize AutoStitchIncrement;

@synthesize BubblePos;

@synthesize HideStartNumber;
@synthesize HideEndNumber;
@synthesize HideAllNumbers;
@synthesize ShowNumbersAtIntervals;

@synthesize HideStartNotch;
@synthesize HideEndNotch;
@synthesize HideAllNotches;
@synthesize ShowNotchesAtIntervals;

@synthesize MarkerValuePositions;
@synthesize UserJumps;

@synthesize DisplayNumberOffset;
@synthesize DisplayNumberMultiplier;
@synthesize DisplayNumberDP;

-(void)readyRender
{
    for (DWBehaviour *b in behaviours) {
        if ([b isKindOfClass:[BNLineRamblerRender class]])
        {
            bnRender=(BNLineRamblerRender*)b;
        }
    }
}

-(void) drawFromMid:(CGPoint)mid andYOffset:(float)yOffset
{
    [bnRender drawFromMid:mid andYOffset:yOffset];
}


-(void)dealloc
{
    self.MinValue=nil;
    self.MaxValue=nil;
    self.ShowNumbersAtIntervals=nil;
    self.ShowNotchesAtIntervals=nil;
    
    self.MarkerValuePositions=nil;

    self.UserJumps=nil;
    
    [super dealloc];
}


@end
