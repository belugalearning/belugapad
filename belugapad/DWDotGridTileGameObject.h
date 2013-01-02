//
//  DWDotGridTileGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "LogPoller.h"
#import "LogPollingProtocols.h"

@class DWDotGridAnchorGameObject;
@class DWDotGridShapeGameObject;

typedef enum {
    kTopLeft=0,
    kTopRight=1,
    kBottomLeft=2,
    kBottomRight=3,
    kBorderLeft=4,
    kBorderRight=5,
    kBorderTop=6,
    kBorderBottom=7,
    kEndCapLeft=8,
    kEndCapRight=9,
    kEndCapTop=10,
    kEndCapBottom=11,
    kMidPieceVertical=12,
    kMidPieceHorizontal=13,
    kNoBorder=14,
    kFullBorder=15
} TileType;

typedef struct {
    float Rotation;
    NSString *spriteFileName;
} tileProperties;

@interface DWDotGridTileGameObject : DWGameObject <LogPolling, LogPollPositioning>

@property TileType tileType;
@property (retain) CCSprite *mySprite;
@property (retain) CCSprite *selectedSprite;
@property CGPoint Position;
@property BOOL Selected;
@property int tileSize;
@property (retain) DWDotGridAnchorGameObject *myAnchor;
@property (retain) CCLayer *RenderLayer;
@property (retain) DWDotGridShapeGameObject *myShape;

@end
