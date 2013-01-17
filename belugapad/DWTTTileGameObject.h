//
//  DWDotGridAnchorGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"
#import "ToolConsts.h"

@interface DWTTTileGameObject : DWGameObject

@property CGPoint Position;
@property int Size;
@property BOOL Disabled;
@property BOOL Selected;
@property (retain) CCSprite *mySprite;
@property (retain) CCSprite *selSprite;
@property (retain) CCSprite *ansSprite;
@property (retain) CCLabelTTF *myText;
@property int myXpos;
@property int myYpos;
@property OperatorMode operatorType;
@property BOOL isEndXPiece;
@property BOOL isEndYPiece;
@property BOOL isCornerPiece;


@end
