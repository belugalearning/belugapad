//
//  DWPieSplitterPieGameObject.h
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "ToolConsts.h"

@interface DWPieSplitterPieGameObject : DWGameObject

@property CGPoint Position;
@property CGPoint MountPosition;
@property (retain) CCSprite *mySprite;
@property (retain) NSMutableArray *mySlices;
@property (retain) NSMutableArray *slicesInMe;
@property BOOL ScaledUp;
@property BOOL HasSplit;
@property int numberOfSlices;
@property (retain) CCSprite *touchOverlay;
@property BOOL Touchable;

@end