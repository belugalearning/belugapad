//
//  DWNBondRowGameObject.h
//  belugapad
//
//  Created by David Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"
#import "LogPollingProtocols.h"

@interface DWNBondRowGameObject : DWGameObject <LogPolling, LogPollPositioning>

@property float MaximumValue;
@property (retain) NSMutableArray *MountedObjects;
@property (retain) NSMutableArray *HintObjects;
@property BOOL Locked;
@property CGPoint Position;
@property int Length;
@property (retain) CCNode *BaseNode;
@property float MyHeldValue;



@end
