//
//  DWPieSplitterSliceGameObject.h
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "ToolConsts.h"

@interface DWPieSplitterSliceGameObject : DWGameObject

@property CGPoint Position;
@property (retain) CCSprite *mySprite;
@property (retain) DWGameObject *myPie;
@property float Rotation;
@property (retain) DWGameObject *myCont;
@property (retain) NSString *SpriteFileName;

@end