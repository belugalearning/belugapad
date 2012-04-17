//
//  DWDotGridTileGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"

typedef enum {
    kTopLeft=0,
    kTopRight=1,
    kBottomLeft=2,
    kBottomRight=3,
    kBorderLeft=4,
    kBorderRight=5,
    kBorderTop=6,
    kBorderBottom=7,
    kNoBorder=8
} TileType;

@interface DWDotGridTileGameObject : DWGameObject

@property TileType tileType;
@property (retain) CCSprite *mySprite;
@property CGPoint Position;

@end
