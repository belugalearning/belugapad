//
//  DWRamblerGameObject.h
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"

@interface DWRamblerGameObject : DWGameObject

@property float Value;
@property float StartValue;
@property float DefaultSegmentSize;
@property float CurrentSegmentValue;
@property CGPoint Pos;
@property (retain) NSNumber *MinValue;
@property (retain) NSNumber *MaxValue;

@property float TouchXOffset;

@property BOOL RenderStitches;
@property int AutoStitchIncrement;


@property int BubblePos;

@end
