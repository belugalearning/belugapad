//
//  DWDotGridAnchorGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"

@interface DWDotGridAnchorGameObject : DWGameObject

@property CGPoint Position;
@property BOOL StartAnchor;
@property BOOL Disabled;
@property BOOL CurrentlySelected;
@property (retain) CCSprite *mySprite;

@end
