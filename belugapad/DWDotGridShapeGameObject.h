//
//  DWDotGridShapeGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"
@class DWDotGridHandleGameObject;
@class DWDotGridAnchorGameObject;
@class DWDotGridShapeGroupGameObject;

@interface DWDotGridShapeGameObject : DWGameObject

@property (retain) NSMutableArray *tiles;
@property (retain) DWDotGridHandleGameObject *moveHandle;
@property (retain) DWDotGridHandleGameObject *resizeHandle;
@property BOOL Disabled;
@property BOOL SelectAllTiles;
@property BOOL RenderDimensions;
@property (retain) DWDotGridAnchorGameObject *firstAnchor;
@property (retain) DWDotGridAnchorGameObject *lastAnchor;

@property (retain) DWDotGridAnchorGameObject *firstBoundaryAnchor;
@property (retain) DWDotGridAnchorGameObject *lastBoundaryAnchor;


@property (retain) CCLabelTTF *myWidth;
@property (retain) CCLabelTTF *myHeight;
@property (retain) DWGameObject *shapeGroup;
@property (retain) CCLayer *RenderLayer;
@property (retain) DWGameObject *MyNumberWheel;
@property BOOL autoUpdateWheel;
@property (retain) NSString *countLabelType;
@property (retain) CCLabelTTF *countLabel;
@property (retain) CCSprite *countBubble;

@end
