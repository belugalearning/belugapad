//
//  DWDotGridAnchorGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"

@interface DWTTTileGameObject : DWGameObject

@property CGPoint Position;
@property BOOL Disabled;
@property (retain) CCSprite *mySprite;
@property (retain) CCLabelTTF *myText;
@property int myXpos;
@property int myYpos;

@end
