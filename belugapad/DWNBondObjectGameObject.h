//
//  DWNBondObjectGameObject.h
//  belugapad
//
//  Created by David Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"
#import "LogPollingProtocols.h"

@class DWNBondRowGameObject;

@interface DWNBondObjectGameObject : DWGameObject <LogPolling,LogPollPositioning>

@property float ObjectValue;
@property CGPoint Position;
@property CGPoint MovePosition;
@property CGPoint MountPosition;
@property (retain) DWNBondRowGameObject *Mount;
@property (retain) CCNode *BaseNode;
@property int Length;
@property (retain) CCLabelTTF *Label;
@property BOOL InitedObject;
@property BOOL IsScaled;
@property BOOL NoScaleBlock;
@property int IndexPos;
@property int lastZIndex;
@property BOOL HintObject;


@end
