//
//  DWDotGridAnchorGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"
#import "LogPollingProtocols.h"

@interface DWDotGridAnchorGameObject : DWGameObject <LogPolling, LogPollPositioning>

@property CGPoint Position;
@property BOOL StartAnchor;
@property BOOL Disabled;
@property BOOL Hidden;
@property (retain) CCSprite *mySprite;
@property int myXpos;
@property int myYpos;
@property BOOL resizeHandle;
@property BOOL moveHandle;
@property (retain) DWGameObject *tile;
@property (retain) CCLayer *RenderLayer;
@property int anchorSize;

@end
