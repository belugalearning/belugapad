//
//  DWDotGridHandleGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"
#import "DWDotGridShapeGameObject.h"
#import "LogPollingProtocols.h"

typedef enum {
    kMoveHandle=0,
    kResizeHandle=1
} HandleType;

@interface DWDotGridHandleGameObject : DWGameObject <LogPolling, LogPollPositioning>

@property HandleType handleType;
@property CGPoint Position;
@property (retain) CCSprite *mySprite;
@property (retain) DWDotGridShapeGameObject *myShape;
@property (retain) CCLayer *RenderLayer;

@end
