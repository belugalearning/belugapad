//
//  DWPieSplitterContainerGameObject.h
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "ToolConsts.h"

@interface DWPieSplitterContainerGameObject : DWGameObject

@property CGPoint Position;
@property CGPoint MountPosition;
@property float RealYPosOffset;
//@property (retain) CCSprite *mySprite;
@property (retain) NSMutableArray *mySlices;
@property BOOL ScaledUp;
@property (retain) NSString *textString;
@property (retain) CCNode *BaseNode;
@property (retain) NSMutableArray *Nodes;
@property (retain) CCSprite *mySprite;
@property (retain) CCNode *labelNode;
@property (retain) CCLabelTTF *wholeNum;
@property (retain) CCLabelTTF *fractNum;
@property (retain) CCLabelTTF *fractDenom;
@property (retain) CCLabelTTF *decimalNum;
@property (retain) CCSprite *fractLine;
@property BOOL Touchable;

-(CGRect)returnLabelBox;

@end